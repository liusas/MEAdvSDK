//
//  MobiSplashAdapter.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import "MobiSplashAdapter.h"
#import "MobiSplash.h"
#import "MobiConfig.h"
#import "MobiAdTargeting.h"
#import "MobiSplashCustomEvent.h"
#import "MPConstants.h"
#import "MPError.h"
#import "MobiAnalyticsTracker.h"

#import "MobiTimer.h"
#import "MobiRealTimeTimer.h"

@interface MobiSplashAdapter () <MobiSplashCustomEventDelegate>

@property (nonatomic, strong) id<MobiSplashCustomEvent> splashCustomEvent;
@property (nonatomic, strong) MobiConfig *configuration;
/// 广告加载超时计时器,超过指定时长后,回调上层广告请求超时而失败,并置delegate=nil,即使custom event回调回来,也不回调给上层
@property (nonatomic, strong) MobiTimer *timeoutTimer;
/// 是否上报了广告展示
@property (nonatomic, assign) BOOL hasTrackedImpression;
/// 是否上报了广告点击
@property (nonatomic, assign) BOOL hasTrackedClick;
// 只允许回调一次加载成功事件,因为缓存加载成功也会走相同回调
@property (nonatomic, assign) BOOL hasSuccessfullyLoaded;
// 只允许回调一次超时事件,因为加载成功事件也只回调一次..
@property (nonatomic, assign) BOOL hasExpired;
// 记录从加载成功到展示广告的时间,超出一定时间则回调超时,广告失效,默认时间为4小时
@property (nonatomic, strong) MobiRealTimeTimer *expirationTimer;

@end

@implementation MobiSplashAdapter

- (instancetype)initWithDelegate:(id<MobiSplashAdapterDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }

    return self;
}

- (void)dealloc {
    // 为防止custom event无法释放,在此处告诉custom event,我们不再需要你了,让它自行处理是否释放其他内存
    [_splashCustomEvent handleCustomEventInvalidated];
    // 释放timer
    [_timeoutTimer invalidate];

    // 确保custom event不是和adapter同步释放,因为有可能custom event持有的对象会在回调adapter后,继续处理一些其他事情,如果都释放了,可能导致这些事情没做完.
//    [[MPCoreInstanceProvider sharedProvider] keepObjectAliveForCurrentRunLoopIteration:_rewardedVideoCustomEvent];
}

/**
 * 当我们从服务器获得响应时,调用此方法获取一个广告
 *
 * @param configuration 加载广告所需的一些配置信息
 8 @param targeting 获取精准化广告目标所需的一些参数
 */
- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting {
//    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);
    self.configuration = configuration;
    id<MobiSplashCustomEvent> customEvent = [[configuration.customEventClass alloc] init];
    if (![customEvent conformsToProtocol:@protocol(MobiSplashCustomEvent)]) {
        NSError * error = [NSError customEventClass:configuration.customEventClass doesNotInheritFrom:MobiSplashCustomEvent.class];
//        MPLogEvent([MPLogEvent error:error message:nil]);
        [self.delegate splashAdFailToPresentForAdapter:self withError:error];
        return;
    }
    customEvent.delegate = self;
    customEvent.localExtras = targeting.localExtras;
    
    self.splashCustomEvent = customEvent;
    [self startTimeoutTimer];
    
    [self.splashCustomEvent requestSplashWithCustomEventInfo:configuration adMarkup:nil];
}

/**
 * 判断现在是否有可用的广告可供展示
 */
- (BOOL)hasAdAvailable {
    return [self.splashCustomEvent hasAdAvailable];
}

/**
 * 播放一个激励视频
 *
 * @param window 用来弹出播放器控制器的控制器
 */
- (void)presentSplashFromWindow:(UIWindow *)window {
    
    [self.splashCustomEvent presentSplashFromWindow:window];
}

/**
* 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
* 当然广告失效后需要回调`[-splashAdDidExpireForAdapter:]`方法告诉用户这个广告已不再有效
*/
- (void)handleAdPlayedForCustomEventNetwork {
    [self.splashCustomEvent handleAdPlayedForCustomEventNetwork];
}

#pragma mark - Metrics
- (void)trackImpression {
    [[MobiAnalyticsTracker sharedTracker] trackImpressionForConfiguration:self.configuration];
    self.hasTrackedImpression = YES;
    [self.expirationTimer invalidate];
//    [self.delegate rewardedVideoDidReceiveImpressionEventForAdapter:self];
}

- (void)trackClick {
    [[MobiAnalyticsTracker sharedTracker] trackClickForConfiguration:self.configuration];
}

// MARK: - MobiSplashCustomEventDelegate
/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    // 不能多次回调加载成功,有时custom event在后台缓存加载成功了也走这个回调
    if (self.hasSuccessfullyLoaded) {
        return;
    }

    self.hasSuccessfullyLoaded = YES;
    // 停止广告加载的计时
    [self didStopLoading];
    [self.delegate splashAdDidLoadForAdapter:self];

    // 记录从广告资源加载成功,到展示的时长,超出指定时长,则认定广告失效
    __weak __typeof__(self) weakSelf = self;
    self.expirationTimer = [[MobiRealTimeTimer alloc] initWithInterval:[MPConstants adsExpirationInterval] block:^(MobiRealTimeTimer *timer){
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.hasTrackedImpression) {
            [strongSelf splashAdDidExpireForCustomEvent:strongSelf.splashCustomEvent];
        }
        [strongSelf.expirationTimer invalidate];
    }];
    [self.expirationTimer scheduleNow];
}

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForCustomEvent:(MobiSplashCustomEvent *)splashAd withError:(NSError *)error {
    // 让custom event和adapter断开连接,这个方法的作用于,有别的对象强引用了custom event,为了不再使用custom event后,custom event能够释放掉,从而调用这个方法,如果能保证custom event一定能释放掉,甚至不必调用这个方法
    [self.splashCustomEvent handleCustomEventInvalidated];
    self.splashCustomEvent = nil;
    // 停止加载计时
    [self didStopLoading];
    // 回调上层,广告加载失败
    [self.delegate splashAdFailToPresentForAdapter:self withError:error];
}

/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdSuccessPresentScreenForAdapter:self];
}

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdApplicationWillEnterBackgroundForAdapter:self];
}

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    // 若允许自动上报广告曝光,则在页面展示出来时上报
    if ([self.splashCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedImpression) {
        [self trackImpression];
    }

    [self.delegate splashAdSuccessPresentScreenForAdapter:self];
}

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    // 若允许自动上报点击事件,则在此处上报点击
    if ([self.splashCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedClick) {
        self.hasTrackedClick = YES;
        [self trackClick];
    }

    [self.delegate splashAdClickedForAdapter:self];
}

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdWillClosedForAdapter:self];
}

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdClosedForAdapter:self];
}

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpireForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    // 只提示一次广告过期
    if (self.hasExpired) {
        return;
    }

    self.hasExpired = YES;
    [self.delegate splashAdDidExpireForAdapter:self];
}

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdWillPresentFullScreenModalForAdapter:self];
}

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdDidPresentFullScreenModalForAdapter:self];
}

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdWillDismissFullScreenModalForAdapter:self];
}

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd {
    [self.delegate splashAdDidDismissFullScreenModalForAdapter:self];
}

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdLifeTime:(NSUInteger)time {
    [self.delegate splashAdLifeTime:time];
}

// MARK: - Private
- (void)startTimeoutTimer {
    NSTimeInterval timeInterval = (self.configuration && self.configuration.adTimeoutInterval >= 0) ?
    self.configuration.adTimeoutInterval : REWARDED_VIDEO_TIMEOUT_INTERVAL;

    if (timeInterval > 0) {
        self.timeoutTimer = [MobiTimer timerWithTimeInterval:timeInterval
                                                    target:self
                                                  selector:@selector(timeout)
                                                   repeats:NO];
        [self.timeoutTimer scheduleNow];
    }
}

- (void)timeout {
    NSError * error = [NSError errorWithCode:MOPUBErrorAdRequestTimedOut localizedDescription:@"Splash ad request timed out"];
    [self.delegate splashAdFailToPresentForAdapter:self withError:error];
    self.delegate = nil;
}

- (void)didStopLoading {
    [self.timeoutTimer invalidate];
}

@end
