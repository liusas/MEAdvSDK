//
//  MobiFullscreenAdManager.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import "MobiFullscreenAdManager.h"
#import "MobiFullscreenAdapter.h"
#import "MobiAdConfigServer.h"
#import "MobiConfig.h"
#import "NSMutableArray+MPAdditions.h"
#import "NSDate+MPAdditions.h"
#import "NSError+MPAdditions.h"
#import "MPError.h"
#import "MPLogging.h"
#import "MPStopwatch.h"
#import "MobiFullscreenError.h"
#import "MobiAdServerURLBuilder.h"

#import "StrategyFactory.h"
#import "MELogTracker.h"

@interface MobiFullscreenAdManager ()<MobiAdConfigServerDelegate, MobiFullscreenVideoAdapterDelegate>

@property (nonatomic, strong) MobiFullscreenAdapter *adapter;
@property (nonatomic, strong) MobiAdConfigServer *communicator;
@property (nonatomic, strong) MobiConfig *configuration;
@property (nonatomic, strong) NSMutableArray<MobiConfig *> *remainingConfigurations;
@property (nonatomic, strong) NSURL *mostRecentlyLoadedURL;  // ADF-4286: avoid infinite ad reloads
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL playedAd;
@property (nonatomic, assign) BOOL ready;
/// 从广告开始加载到加载成功或加载失败的时间间隔
@property (nonatomic, strong) MPStopwatch *loadStopwatch;

@end


@implementation MobiFullscreenAdManager


- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiFullscreenAdManagerDelegate>)delegate {
    if (self = [super init]) {
        _posid = [posid copy];
        _communicator = [[MobiAdConfigServer alloc] initWithDelegate:self];
        _delegate = delegate;
        _loadStopwatch = MPStopwatch.new;
        _remainingConfigurations = [NSMutableArray array];
    }

    return self;
}

- (void)dealloc {
    [_communicator cancel];
}

- (Class)customEventClass
{
    return self.configuration.customEventClass;
}

/**
 * 加载激励视频广告
 * @param userId 用户的唯一标识
 * @param targeting 精准广告投放的一些参数,可为空
 */
- (void)loadFullscreenVideoAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting {
    self.playedAd = NO;

    if (self.loading) {
        MPLogEvent([MPLogEvent error:NSError.adAlreadyLoading message:nil]);
        return;
    }
    
    // 若视频广告已经准备好展示了,我们就告诉上层加载完毕;若当前ad manager正在展示视频广告,则继续请求视频广告资源
    if (self.ready && !self.playedAd) {
        // 若已经有广告了,就不需要再绑定userid了,因为有可能这个广告已经绑定了旧的userid.
        [self.delegate fullscreenVideoDidLoadForAdManager:self];
    } else {
        // 这里设置userid会覆盖我们之前设置的userid,在其他广告展示时我们会用这个新的userid
        self.userId = userId;
        self.targeting = targeting;
        // 获取 MEConfig 类型的数组,其中包含具体平台的广告位 id 和响应 network 的 custom event 执行类
        NSArray *configurations = [[StrategyFactory sharedInstance] getConfigurationsWithAdType:MobiAdTypeFullScreenVideo sceneId:self.posid];
        if (configurations.count) {
            [self assignCofigurationToPlay:configurations];
        } else {
            // 若分配失败,则提示错误
            NSString *errorDescription = [NSString stringWithFormat:@"assign network error"];
            NSError * clearResponseError = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain
                                                               code:MobiFullscreenVideoAdErrorUnknown
                                                           userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
            [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:clearResponseError];
        }
    }
}


/**
 * 判断这个ad manager下的广告是否是有效且可以直接展示的
 */
- (BOOL)hasAdAvailable {
    // 广告未准备好,或已经过期
    if (!self.ready) {
        return NO;
    }
    
    // 若正在展示广告,则返回No,因为我们不允许同时播放两个视频广告
    if (self.playedAd) {
        return NO;
    }
    
    // 让adapter从Custom evnet中得知这个广告是否有效
    return [self.adapter hasAdAvailable];
}

/**
 * 弹出激励视频广告
 *
 * @param viewController 用来present出视频控制器的控制器
 */
- (void)presentFullscreenVideoAdFromViewController:(UIViewController *)viewController {
    // 若广告没准备好,则不展示
    if (!self.ready) {
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorNoAdReady userInfo:@{ NSLocalizedDescriptionKey: @"Fullscreen video ad view is not ready to be shown"}];
//        MPLogInfo(@"%@ error: %@", NSStringFromSelector(_cmd), error.localizedDescription);
        [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    // 若当前正在展示广告,则不展示这个广告,激励视频每次只能展示一个
    if (self.playedAd) {
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorAdAlreadyPlayed userInfo:nil];
        [self.delegate fullscreenVideoAdDidPlayFinishForAdManager:self didFailWithError:error];
        return;
    }
    
    // 通过adapter调用custom event执行广告展示
    [self.adapter presentFullscreenVideoFromViewController:viewController];
}

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 */
- (void)handleAdPlayedForCustomEventNetwork {
    // 只有在广告已经准备好展示时,告诉后台广告平台做相应处理
    if (self.ready) {
        [self.adapter handleAdPlayedForCustomEventNetwork];
    }
}

// MARK: - Private
- (void)loadAdWithURL:(NSURL *)URL {
    self.playedAd = NO;

    if (self.loading) {
//        MPLogEvent([MPLogEvent error:NSError.adAlreadyLoading message:nil]);
        return;
    }

    self.loading = YES;
    self.mostRecentlyLoadedURL = URL;
    [self.communicator loadURL:URL];
}

- (void)fetchAdWithConfiguration:(MobiConfig *)configuration {
//    MPLogInfo(@"Rewarded video ad is fetching ad type: %@", configuration.adType);

    if (configuration.adUnitWarmingUp) {
//        MPLogInfo(kMPWarmingUpErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorAdUnitWarmingUp userInfo:nil];
        [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    if (configuration.adType == MobiAdTypeUnknown) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    // 告诉服务器马上要加载广告了
//    [self.communicator sendBeforeLoadUrlWithConfiguration:configuration];

    // 开始加载计时
    [self.loadStopwatch start];

    MobiFullscreenAdapter *adapter = [[MobiFullscreenAdapter alloc] initWithDelegate:self];

    if (adapter == nil) {
        // 提示应用未知错误
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorUnknown userInfo:nil];
        [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    self.adapter = adapter;
    // 让adapter找到合适的custom event请求拉取视频广告
    [self.adapter getAdWithConfiguration:configuration targeting:self.targeting];
}

/// 加载失败后的统一处理,需要查看是否有备用广告平台可选
- (void)loadFailedOperationwithError:(NSError *)error {
    if (self.loadStopwatch.isRunning) {
        [self.loadStopwatch stop];
    }
    // 若请求拉取下来多个配置,则尝试用不同配置拉取一下广告
    if (self.remainingConfigurations.count > 0) {
        // 取出配置后就把这个配置从配置数组中删除了
        self.configuration = [self.remainingConfigurations removeFirst];
        [self fetchAdWithConfiguration:self.configuration];
    } else {
        // 若没有广告配置可用,也没有备用url可拉取广告配置,则提示没有广告
        self.ready = NO;
        self.loading = NO;
        NSString *errorDescription = [NSString stringWithFormat:@"There are no ads of this posid = %@", self.adUnitId];
        NSError * clearResponseError = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain
                                                           code:MobiFullscreenVideoAdErrorNoAdsAvailable
                                                       userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        //        MPLogAdEvent([MPLogEvent adFailedToLoadWithError:clearResponseError], self.adUnitId);
        [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:error];
    }
}

// MARK: - MobiAdConfigServerDelegate
/// 分配广告平台去展示广告
- (void)assignCofigurationToPlay:(NSArray<MobiConfig *> *)configurations {
    self.remainingConfigurations = [configurations mutableCopy];
    self.configuration = [self.remainingConfigurations removeFirst];

    // 若分配的平台是自有平台,则在此请求新内容
    if ([self.configuration.adapterProvider isKindOfClass:NSClassFromString(@"MEMobipubAdapter")]) {
        [self loadAdWithURL:[MobiAdServerURLBuilder URLWithAdPosid:self.posid targeting:self.targeting]];
        return;
    }
    
    // 若没拉回来广告配置,则可能是kAdTypeClear类型(暂时没广告)
    if (self.remainingConfigurations.count == 0 && self.configuration == nil) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:error];
        return;
    }
    
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

    [self fetchAdWithConfiguration:self.configuration];
}

/// 请求服务器拉取广告配置成功的回调
- (void)communicatorDidReceiveAdConfigurations:(NSArray<MobiConfig *> *)configurations {
    for (MobiConfig *object in [configurations reverseObjectEnumerator]) {
        [self.remainingConfigurations insertObject:object atIndex:0];
    }
    
    self.configuration = [self.remainingConfigurations removeFirst];

    // There are no configurations to try. Consider this a clear response by the server.
    // 若没拉回来广告配置,则可能是kAdTypeClear类型(暂时没广告)
    if (self.remainingConfigurations.count == 0 && self.configuration == nil) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate fullscreenVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    [self fetchAdWithConfiguration:self.configuration];
}

- (void)communicatorDidFailWithError:(NSError *)error {
    [self loadFailedOperationwithError:error];
}

- (BOOL)isFullscreenAd {
    return YES;
}

- (NSString *)adUnitId {
    return self.posid;
}


#pragma mark - MobiFullscreenVideoAdapterDelegate
- (void)fullscreenVideoDidLoadForAdAdapter:(MobiFullscreenAdapter *)adapter {
    self.remainingConfigurations = nil;
    self.ready = YES;
    self.loading = NO;

    // 记录该广告从开始加载,到加载完成的时长,并上报
    NSTimeInterval duration = [self.loadStopwatch stop];
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:MPAfterLoadResultAdLoaded];

//    MPLogAdEvent(MPLogEvent.adDidLoad, self.adUnitId);
    [self.delegate fullscreenVideoDidLoadForAdManager:self];
}

- (void)fullscreenVideoAdVideoDidLoadForAdAdapter:(MobiFullscreenAdapter *)adapter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fullscreenVideoAdVideoDidLoadForAdManager:)]) {
        [self.delegate fullscreenVideoAdVideoDidLoadForAdManager:self];
    }
}

- (void)fullscreenVideoDidFailToLoadForAdAdapter:(MobiFullscreenAdapter *)adapter error:(NSError *)error {
    // 记录加载失败的时长,并在MobiAdConfigServer中判断选择合适URL上报失败日志
    NSTimeInterval duration = [self.loadStopwatch stop];
//    MPAfterLoadResult result = (error.isAdRequestTimedOutError ? MPAfterLoadResultTimeout : (adapter == nil ? MPAfterLoadResultMissingAdapter : MPAfterLoadResultError));
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:result];

    [self loadFailedOperationwithError:error];
}

- (void)fullscreenVideoDidExpireForAdAdapter:(MobiFullscreenAdapter *)adapter {
    self.ready = NO;

//    MPLogAdEvent([MPLogEvent adExpiredWithTimeInterval:MPConstants.adsExpirationInterval], self.adUnitId);
    [self.delegate fullscreenVideoDidExpireForAdManager:self];
}

- (void)fullscreenVideoAdViewRenderFailForAdAdapter:(MobiFullscreenAdapter *)adapter error:(NSError *)error {
    self.ready = NO;
    self.playedAd = NO;

    [self.delegate fullscreenVideoAdViewRenderFailForAdManager:self error:error];
}

- (void)fullscreenVideoWillAppearForAdAdapter:(MobiFullscreenAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillAppear, self.adUnitId);
    [self.delegate fullscreenVideoWillAppearForAdManager:self];
    // 更改广告展示的频率
    [StrategyFactory changeAdFrequencyWithSceneId:self.posid];
}

- (void)fullscreenVideoDidAppearForAdAdapter:(MobiFullscreenAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adDidAppear, self.adUnitId);
    [self.delegate fullscreenVideoDidAppearForAdManager:self];
}

- (void)fullscreenVideoAdDidPlayFinishForAdAdapter:(MobiFullscreenAdapter *)adapter didFailWithError:(NSError *)error {
    // 若视频播放失败,则立即重置激励视频状态,保证下一个广告可以正常播放
    self.ready = NO;
    self.playedAd = NO;
    
    [self.delegate fullscreenVideoAdDidPlayFinishForAdManager:self didFailWithError:error];
}

- (void)fullscreenVideoWillDisappearForAdAdapter:(MobiFullscreenAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillDisappear, self.adUnitId);
    [self.delegate fullscreenVideoWillDisappearForAdManager:self];
}

- (void)fullscreenVideoDidDisappearForAdAdapter:(MobiFullscreenAdapter *)adapter {
    // Successful playback of the rewarded video; reset the internal played state.
    self.ready = NO;
    self.playedAd = YES;

//    MPLogAdEvent(MPLogEvent.adDidDisappear, self.adUnitId);
    [self.delegate fullscreenVideoDidDisappearForAdManager:self];
}

- (void)fullscreenVideoDidReceiveTapEventForAdAdapter:(MobiFullscreenAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillPresentModal, self.adUnitId);
    [self.delegate fullscreenVideoDidReceiveTapEventForAdManager:self];
}

- (void)fullscreenVideoDidReceiveImpressionEventForAdAdapter:(MobiFullscreenAdapter *)adapter {
//    [self.delegate fullscreenVideoAdManager:self didReceiveImpressionEventWithImpressionData:self.configuration.impressionData];
}

- (void)fullscreenVideoWillLeaveApplicationForAdAdapter:(MobiFullscreenAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillLeaveApplication, self.adUnitId);
    [self.delegate fullscreenVideoWillLeaveApplicationForAdManager:self];
}

- (void)fullscreenVideoAdDidClickSkip:(MobiFullscreenAdapter *)adapter {
    [self.delegate fullscreenVideoAdDidClickSkip:self];
}

- (NSString *)fullscreenVideoAdUnitId {
    return self.adUnitId;
}

- (NSString *)fullscreenVideoCustomerId {
    return self.userId;
}


@end
