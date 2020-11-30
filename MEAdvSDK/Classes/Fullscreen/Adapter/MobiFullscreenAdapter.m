//
//  MobiFullscreenAdapter.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import "MobiFullscreenAdapter.h"
#import "MobiFullscreen.h"
#import "MobiConfig.h"
#import "MobiAdTargeting.h"
#import "MobiFullscreenCustomEvent.h"
#import "MPConstants.h"
#import "MPError.h"
#import "MobiAnalyticsTracker.h"

#import "MobiTimer.h"
#import "MobiRealTimeTimer.h"

#import "MELogTracker.h"

@interface MobiFullscreenAdapter () <MobiFullscreenVideoCustomEventDelegate>

@property (nonatomic, strong) id<MobiFullscreenVideoCustomEvent> fullscreenVideoCustomEvent;
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

@implementation MobiFullscreenAdapter

- (instancetype)initWithDelegate:(id<MobiFullscreenVideoAdapterDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }

    return self;
}


- (void)dealloc {
    // 为防止custom event无法释放,在此处告诉custom event,我们不再需要你了,让它自行处理是否释放其他内存
    [_fullscreenVideoCustomEvent handleCustomEventInvalidated];
    // 释放timer
    [_timeoutTimer invalidate];

    // 确保custom event不是和adapter同步释放,因为有可能custom event持有的对象会在回调adapter后,继续处理一些其他事情,如果都释放了,可能导致这些事情没做完.
//    [[MPCoreInstanceProvider sharedProvider] keepObjectAliveForCurrentRunLoopIteration:_fullscreenVideoCustomEvent];
}

/**
 * 当我们从服务器获得响应时,调用此方法获取一个广告
 *
 * @param configuration 加载广告所需的一些配置信息
 8 @param targeting 获取精准化广告目标所需的一些参数
 */
- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting {
    self.configuration = configuration;
    id<MobiFullscreenVideoCustomEvent> customEvent = [[configuration.customEventClass alloc] init];
    if (![customEvent conformsToProtocol:@protocol(MobiFullscreenVideoCustomEvent)]) {
        NSError * error = [NSError customEventClass:configuration.customEventClass doesNotInheritFrom:MobiFullscreenCustomEvent.class];
        [self.delegate fullscreenVideoDidFailToLoadForAdAdapter:self error:error];
        return;
    }
    customEvent.delegate = self;
    customEvent.localExtras = targeting.localExtras;
    
    self.fullscreenVideoCustomEvent = customEvent;
    [self startTimeoutTimer];
    
    [self.fullscreenVideoCustomEvent requestFullscreenVideoWithCustomEventInfo:@{@"adunit":configuration.adUnitId} adMarkup:nil];
}

/**
 * 判断现在是否有可用的广告可供展示
 */
- (BOOL)hasAdAvailable {
    return [self.fullscreenVideoCustomEvent hasAdAvailable];
}

/**
 * 播放一个激励视频
 *
 * @param viewController 用来弹出播放器控制器的控制器
 */
- (void)presentFullscreenVideoFromViewController:(UIViewController *)viewController {
    [self.fullscreenVideoCustomEvent presentFullscreenVideoFromViewController:viewController];
}

- (void)handleAdPlayedForCustomEventNetwork {
    [self.fullscreenVideoCustomEvent handleAdPlayedForCustomEventNetwork];
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
    NSError * error = [NSError errorWithCode:MOPUBErrorAdRequestTimedOut localizedDescription:@"Fullscreen video ad request timed out"];
    [self.delegate fullscreenVideoDidFailToLoadForAdAdapter:self error:error];
    self.delegate = nil;
}

- (void)didStopLoading {
    [self.timeoutTimer invalidate];
}

//- (NSURL *)fullscreenVideoCompletionUrlByAppendingClientParams {
//    NSString * sourceCompletionUrl = self.configuration.fullscreenVideoCompletionUrl;
//    NSString * customerId = ([self.delegate respondsToSelector:@selector(fullscreenVideoCustomerId)] ? [self.delegate fullscreenVideoCustomerId] : nil);
//    MobifullscreenVideoReward * reward = (self.configuration.selectedReward != nil && ![self.configuration.selectedReward.currencyType isEqualToString:kMobifullscreenVideoRewardCurrencyTypeUnspecified] ? self.configuration.selectedReward : nil);
//    NSString * customEventName = NSStringFromClass([self.fullscreenVideoCustomEvent class]);
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
//    [self.delegate fullscreenVideoDidReceiveImpressionEventForAdAdapter:self];
}

/// 数组中存放的是 url 的字符串
- (void)trackProgressImpressionWithUrlArr:(NSArray *)urls {
    [[MobiAnalyticsTracker sharedTracker] sendTrackingRequestForURLStrs:urls];
}

- (void)trackClick {
    [[MobiAnalyticsTracker sharedTracker] trackClickForConfiguration:self.configuration];
}

#pragma mark - MobiFullscreenVideoCustomEventDelegate

- (void)fullscreenVideoDidLoadAdForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent {
    // 不能多次回调加载成功,有时custom event在后台缓存加载成功了也走这个回调
    if (self.hasSuccessfullyLoaded) {
        return;
    }

    self.hasSuccessfullyLoaded = YES;
    // 停止广告加载的计时
    [self didStopLoading];
    [self.delegate fullscreenVideoDidLoadForAdAdapter:self];

    // 记录从广告资源加载成功,到展示的时长,超出指定时长,则认定广告失效
    __weak __typeof__(self) weakSelf = self;
    self.expirationTimer = [[MobiRealTimeTimer alloc] initWithInterval:[MPConstants adsExpirationInterval] block:^(MobiRealTimeTimer *timer){
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.hasTrackedImpression) {
            [strongSelf fullscreenVideoDidExpireForCustomEvent:strongSelf.fullscreenVideoCustomEvent];
        }
        [strongSelf.expirationTimer invalidate];
    }];
    [self.expirationTimer scheduleNow];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_FullVideo;
    model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)fullscreenVideoAdVideoDidLoadForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fullscreenVideoAdVideoDidLoadForAdAdapter:)]) {
        [self.delegate fullscreenVideoAdVideoDidLoadForAdAdapter:self];
    }
}

- (void)fullscreenVideoDidFailToLoadAdForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent error:(NSError *)error {
    // 让custom event和adapter断开连接,这个方法的作用于,有别的对象强引用了custom event,为了不再使用custom event后,custom event能够释放掉,从而调用这个方法,如果能保证custom event一定能释放掉,甚至不必调用这个方法
    [self.fullscreenVideoCustomEvent handleCustomEventInvalidated];
    self.fullscreenVideoCustomEvent = nil;
    // 停止加载计时
    [self didStopLoading];
    // 回调上层,广告加载失败
    [self.delegate fullscreenVideoDidFailToLoadForAdAdapter:self error:error];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_FullVideo;
     model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
     
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)fullscreenVideoAdViewRenderFailForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent error:(NSError *_Nullable)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fullscreenVideoAdViewRenderFailForAdAdapter:error:)]) {
        [self.delegate fullscreenVideoAdViewRenderFailForAdAdapter:self error:error];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_RewardVideo;
     model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.type = AdLogFaultType_Render;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];


    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)fullscreenVideoDidExpireForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent
{
    // Only allow one expire per custom event to match up with one successful load callback per custom event.
    // 只提示一次广告过期
    if (self.hasExpired) {
        return;
    }

    self.hasExpired = YES;
    [self.delegate fullscreenVideoDidExpireForAdAdapter:self];
}

- (void)fullscreenVideoWillAppearForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent
{
    [self.delegate fullscreenVideoWillAppearForAdAdapter:self];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Show;
    model.st_t = AdLogAdType_FullVideo;
    model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)fullscreenVideoDidAppearForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent {
    // 若允许自动上报广告曝光,则在页面展示出来时上报
    if ([self.fullscreenVideoCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedImpression) {
        [self trackImpression];
    }

    [self.delegate fullscreenVideoDidAppearForAdAdapter:self];
}

- (void)fullscreenVideoAdDidPlayFinishForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent didFailWithError:(NSError *_Nullable)error {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(fullscreenVideoAdDidPlayFinishForAdAdapter:didFailWithError:)]) {
        [self.delegate fullscreenVideoAdDidPlayFinishForAdAdapter:self didFailWithError:error];
    }
    
    if (error) {
        // 上报日志
        MEAdLogModel *model = [MEAdLogModel new];
        model.event = AdLogEventType_Fault;
        model.st_t = AdLogAdType_RewardVideo;
        model.so_t = self.configuration.sortType;
        model.posid = self.configuration.adUnitId;
        model.network = self.configuration.networkName;
        model.nt_name = self.configuration.ntName;
        model.type = AdLogFaultType_Render;
        model.code = error.code;
        if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
            model.msg = error.localizedDescription;
        }
        model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
        
        
        // 立即上传
        [MELogTracker uploadImmediatelyWithLogModels:@[model]];
    }
}

- (void)fullscreenVideoWillDisappearForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent
{
    [self.delegate fullscreenVideoWillDisappearForAdAdapter:self];
}

- (void)fullscreenVideoDidDisappearForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent
{
    [self.delegate fullscreenVideoDidDisappearForAdAdapter:self];
}

- (void)fullscreenVideoWillLeaveApplicationForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent
{
    [self.delegate fullscreenVideoWillLeaveApplicationForAdAdapter:self];
}

- (void)fullscreenVideoDidReceiveTapEventForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent {
    // 若允许自动上报点击事件,则在此处上报点击
    if ([self.fullscreenVideoCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedClick) {
        self.hasTrackedClick = YES;
        [self trackClick];
    }
    
    [self.delegate fullscreenVideoDidReceiveTapEventForAdAdapter:self];
    
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_FullVideo;
     model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];


    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)fullscreenVideoAdDidClickSkipForCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent {
    [self.delegate fullscreenVideoAdDidClickSkip:self];
}

/// 通过代理获取用户的唯一标识,即userid
- (NSString *)customerIdForfullscreenVideoCustomEvent:(id<MobiFullscreenVideoCustomEvent>)customEvent {
    if ([self.delegate respondsToSelector:@selector(fullscreenVideoCustomerId)]) {
        return [self.delegate fullscreenVideoCustomerId];
    }

    return nil;
}

#pragma mark - MPPrivatefullscreenVideoCustomEventDelegate

- (NSString *)adUnitId {
    if ([self.delegate respondsToSelector:@selector(fullscreenVideoAdUnitId)]) {
        return [self.delegate fullscreenVideoAdUnitId];
    }
    return nil;
}

- (MobiConfig *)configuration {
    return _configuration;
}

@end
