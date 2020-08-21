//
//  MobiRewardedVideoAdapter.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/10.
//

#import "MobiRewardedVideoAdapter.h"
#import "MobiRewardedVideo.h"
#import "MobiRewardedVideoReward.h"
#import "MobiConfig.h"
#import "MobiAdTargeting.h"
#import "MobiRewardedVideoCustomEvent.h"
#import "MPConstants.h"
#import "MPError.h"
#import "MobiAnalyticsTracker.h"

#import "MobiTimer.h"
#import "MobiRealTimeTimer.h"

@interface MobiRewardedVideoAdapter () <MobiRewardedVideoCustomEventDelegate>

@property (nonatomic, strong) id<MobiRewardedVideoCustomEvent> rewardedVideoCustomEvent;
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

@implementation MobiRewardedVideoAdapter

- (instancetype)initWithDelegate:(id<MobiRewardedVideoAdapterDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }

    return self;
}

- (void)dealloc {
    // 为防止custom event无法释放,在此处告诉custom event,我们不再需要你了,让它自行处理是否释放其他内存
    [_rewardedVideoCustomEvent handleCustomEventInvalidated];
    // 释放timer
    [_timeoutTimer invalidate];

    // 确保custom event不是和adapter同步释放,因为有可能custom event持有的对象会在回调adapter后,继续处理一些其他事情,如果都释放了,可能导致这些事情没做完.
//    [[MPCoreInstanceProvider sharedProvider] keepObjectAliveForCurrentRunLoopIteration:_rewardedVideoCustomEvent];
}

- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting {
//    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);
    self.configuration = configuration;
    id<MobiRewardedVideoCustomEvent> customEvent = [[configuration.customEventClass alloc] init];
    if (![customEvent conformsToProtocol:@protocol(MobiRewardedVideoCustomEvent)]) {
        NSError * error = [NSError customEventClass:configuration.customEventClass doesNotInheritFrom:MobiRewardedVideoCustomEvent.class];
//        MPLogEvent([MPLogEvent error:error message:nil]);
        [self.delegate rewardedVideoDidFailToLoadForAdapter:self error:error];
        return;
    }
    customEvent.delegate = self;
    customEvent.localExtras = targeting.localExtras;

    self.rewardedVideoCustomEvent = customEvent;
    [self startTimeoutTimer];

    [self.rewardedVideoCustomEvent requestRewardedVideoWithCustomEventInfo:configuration adMarkup:nil];
}

- (BOOL)hasAdAvailable {
    return [self.rewardedVideoCustomEvent hasAdAvailable];
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController {
    [self.rewardedVideoCustomEvent presentRewardedVideoFromViewController:viewController];
}

- (void)handleAdPlayedForCustomEventNetwork {
    [self.rewardedVideoCustomEvent handleAdPlayedForCustomEventNetwork];
}

#pragma mark - Private

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
    NSError * error = [NSError errorWithCode:MOPUBErrorAdRequestTimedOut localizedDescription:@"Rewarded video ad request timed out"];
    [self.delegate rewardedVideoDidFailToLoadForAdapter:self error:error];
    self.delegate = nil;
}

- (void)didStopLoading {
    [self.timeoutTimer invalidate];
}

//- (NSURL *)rewardedVideoCompletionUrlByAppendingClientParams {
//    NSString * sourceCompletionUrl = self.configuration.rewardedVideoCompletionUrl;
//    NSString * customerId = ([self.delegate respondsToSelector:@selector(rewardedVideoCustomerId)] ? [self.delegate rewardedVideoCustomerId] : nil);
//    MobiRewardedVideoReward * reward = (self.configuration.selectedReward != nil && ![self.configuration.selectedReward.currencyType isEqualToString:kMobiRewardedVideoRewardCurrencyTypeUnspecified] ? self.configuration.selectedReward : nil);
//    NSString * customEventName = NSStringFromClass([self.rewardedVideoCustomEvent class]);
//
//    return [MPAdServerURLBuilder rewardedCompletionUrl:sourceCompletionUrl
//                                        withCustomerId:customerId
//                                            rewardType:reward.currencyType
//                                          rewardAmount:reward.amount
//                                       customEventName:customEventName
//                                        additionalData:self.customData];
//}

#pragma mark - Metrics
- (void)trackImpression {
    [[MobiAnalyticsTracker sharedTracker] trackImpressionForConfiguration:self.configuration];
    self.hasTrackedImpression = YES;
    [self.expirationTimer invalidate];
    [self.delegate rewardedVideoDidReceiveImpressionEventForAdapter:self];
}

/// 数组中存放的是 url 的字符串
- (void)trackProgressImpressionWithUrlArr:(NSArray *)urls {
    [[MobiAnalyticsTracker sharedTracker] sendTrackingRequestForURLStrs:urls];
}

- (void)trackClick {
    [[MobiAnalyticsTracker sharedTracker] trackClickForConfiguration:self.configuration];
}

#pragma mark - MobiRewardedVideoCustomEventDelegate

- (void)rewardedVideoDidLoadAdForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent {
    // 不能多次回调加载成功,有时custom event在后台缓存加载成功了也走这个回调
    if (self.hasSuccessfullyLoaded) {
        return;
    }

    self.hasSuccessfullyLoaded = YES;
    // 停止广告加载的计时
    [self didStopLoading];
    [self.delegate rewardedVideoDidLoadForAdapter:self];

    // 记录从广告资源加载成功,到展示的时长,超出指定时长,则认定广告失效
    __weak __typeof__(self) weakSelf = self;
    self.expirationTimer = [[MobiRealTimeTimer alloc] initWithInterval:[MPConstants adsExpirationInterval] block:^(MobiRealTimeTimer *timer){
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.hasTrackedImpression) {
            [strongSelf rewardedVideoDidExpireForCustomEvent:strongSelf.rewardedVideoCustomEvent];
        }
        [strongSelf.expirationTimer invalidate];
    }];
    [self.expirationTimer scheduleNow];
}

- (void)rewardedVideoAdVideoDidLoadForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoAdVideoDidLoadForAdapter:)]) {
        [self.delegate rewardedVideoAdVideoDidLoadForAdapter:self];
    }
}

- (void)rewardedVideoDidFailToLoadAdForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent error:(NSError *)error {
    // 让custom event和adapter断开连接,这个方法的作用于,有别的对象强引用了custom event,为了不再使用custom event后,custom event能够释放掉,从而调用这个方法,如果能保证custom event一定能释放掉,甚至不必调用这个方法
    [self.rewardedVideoCustomEvent handleCustomEventInvalidated];
    self.rewardedVideoCustomEvent = nil;
    // 停止加载计时
    [self didStopLoading];
    // 回调上层,广告加载失败
    [self.delegate rewardedVideoDidFailToLoadForAdapter:self error:error];
}

- (void)rewardedVideoDidExpireForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent
{
    // Only allow one expire per custom event to match up with one successful load callback per custom event.
    // 只提示一次广告过期
    if (self.hasExpired) {
        return;
    }

    self.hasExpired = YES;
    [self.delegate rewardedVideoDidExpireForAdapter:self];
}

- (void)rewardedVideoDidFailToPlayForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent error:(NSError *)error
{
    [self.delegate rewardedVideoDidFailToPlayForAdapter:self error:error];
}

- (void)rewardedVideoWillAppearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent
{
    [self.delegate rewardedVideoWillAppearForAdapter:self];
}

- (void)rewardedVideoDidAppearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent {
    // 若允许自动上报广告曝光,则在页面展示出来时上报
    if ([self.rewardedVideoCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedImpression) {
        [self trackImpression];
    }

    [self.delegate rewardedVideoDidAppearForAdapter:self];
}

- (void)rewardedVideoWillDisappearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent
{
    [self.delegate rewardedVideoWillDisappearForAdapter:self];
}

- (void)rewardedVideoDidDisappearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent
{
    [self.delegate rewardedVideoDidDisappearForAdapter:self];
}

- (void)rewardedVideoWillLeaveApplicationForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent
{
    [self.delegate rewardedVideoWillLeaveApplicationForAdapter:self];
}

- (void)rewardedVideoDidReceiveTapEventForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent {
    // 若允许自动上报点击事件,则在此处上报点击
    if ([self.rewardedVideoCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedClick) {
        self.hasTrackedClick = YES;
        [self trackClick];
    }

    [self.delegate rewardedVideoDidReceiveTapEventForAdapter:self];
}

- (void)rewardedVideoShouldRewardUserForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent reward:(MobiRewardedVideoReward *)reward {
    // 播放广告打到可以给用户奖励的程度时,从配置中获取选中的奖励,并回传给上层应用
    if (self.configuration) {
        // 从配置中获取选中的奖励,奖励的货币类型,是MobiRewardedVideoReward这个类的currency字段
//        MobiRewardedVideoReward *mopubConfiguredReward = self.configuration.selectedReward;
        
//        if (mopubConfiguredReward && ![mopubConfiguredReward.currencyType isEqualToString:kMobiRewardedVideoRewardCurrencyTypeUnspecified]) {
//            reward = mopubConfiguredReward;
//        }
    }

    if (reward) {
        [self.delegate rewardedVideoShouldRewardUserForAdapter:self reward:reward];
    }
}

/// 通过代理获取用户的唯一标识,即userid
- (NSString *)customerIdForRewardedVideoCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent {
    if ([self.delegate respondsToSelector:@selector(rewardedVideoCustomerId)]) {
        return [self.delegate rewardedVideoCustomerId];
    }

    return nil;
}

#pragma mark - MPPrivateRewardedVideoCustomEventDelegate

- (NSString *)adUnitId {
    if ([self.delegate respondsToSelector:@selector(rewardedVideoAdUnitId)]) {
        return [self.delegate rewardedVideoAdUnitId];
    }
    return nil;
}

- (MobiConfig *)configuration {
    return _configuration;
}

@end
