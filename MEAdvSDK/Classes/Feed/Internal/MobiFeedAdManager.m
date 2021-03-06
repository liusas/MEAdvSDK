//
//  MobiFeedAdManager.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import "MobiFeedAdManager.h"
#import "MobiFeedAdapter.h"
#import "MobiAdConfigServer.h"
#import "MobiConfig.h"
#import "NSMutableArray+MPAdditions.h"
#import "NSDate+MPAdditions.h"
#import "NSError+MPAdditions.h"
#import "MPError.h"
#import "MPLogging.h"
#import "MPStopwatch.h"
#import "MobiFeedError.h"
#import "MobiAdServerURLBuilder.h"
#import "StrategyFactory.h"

#import "MELogTracker.h"

@interface MobiFeedAdManager ()<MobiAdConfigServerDelegate, MobiFeedAdapterDelegate>

@property (nonatomic, strong) MobiFeedAdapter *adapter;
@property (nonatomic, strong) MobiAdConfigServer *communicator;
@property (nonatomic, strong) MobiConfig *configuration;
@property (nonatomic, strong) NSMutableArray<MobiConfig *> *remainingConfigurations;
@property (nonatomic, strong) NSMutableArray<MobiNativeExpressFeedView *> *nativeExpressFeedViews;
@property (nonatomic, strong) NSURL *mostRecentlyLoadedURL;  // ADF-4286: avoid infinite ad reloads
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL ready;
/// 从广告开始加载到加载成功或加载失败的时间间隔
@property (nonatomic, strong) MPStopwatch *loadStopwatch;

@end

@implementation MobiFeedAdManager

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiFeedAdManagerDelegate>)delegate {
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

/**
* 加载信息流广告
* @param userId 用户的唯一标识
* @param targeting 精准广告投放的一些参数,可为空
*/
- (void)loadFeedAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting {
    if (self.loading) {
        MPLogEvent([MPLogEvent error:NSError.adAlreadyLoading message:nil]);
        return;
    }
    
    // 这里设置userid会覆盖我们之前设置的userid,在其他广告展示时我们会用这个新的userid
    self.userId = userId;
    self.targeting = targeting;
    
    // 获取 MEConfig 类型的数组,其中包含具体平台的广告位 id 和响应 network 的 custom event 执行类
    NSArray *configurations = [[StrategyFactory sharedInstance] getConfigurationsWithAdType:MobiAdTypeFeed sceneId:self.adUnitId];
    if (configurations.count) {
        [self assignCofigurationToPlay:configurations targeting:targeting count:self.count];
    } else {
        // 若分配失败,则提示错误
        NSString *errorDescription = [NSString stringWithFormat:@"assign network error"];
        NSError * clearResponseError = [NSError errorWithDomain:MobiFeedAdsSDKDomain
                                                           code:MobiFeedAdErrorUnknown
                                                       userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        [self.delegate nativeExpressAdFailToLoadForAdManager:self error:clearResponseError];
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
    
    // 让adapter从Custom evnet中得知这个广告是否有效
    return [self.adapter hasAdAvailable];
}

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调 `[-nativeExpressAdDidExpireForAdManager:]` 方法告诉用户这个广告已不再有效
 */
- (void)handleAdPlayedForCustomEventNetwork {
    // 只有在广告已经准备好展示时,告诉后台广告平台做相应处理
    if (self.ready) {
        [self.adapter handleAdPlayedForCustomEventNetwork];
    }
}

// MARK: - Private
- (void)loadAdWithURL:(NSURL *)URL {
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
        NSError *error = [NSError errorWithDomain:MobiFeedAdsSDKDomain code:MobiFeedAdErrorAdUnitWarmingUp userInfo:nil];
        [self.delegate nativeExpressAdFailToLoadForAdManager:self error:error];
        return;
    }

    if (configuration.adType == MobiAdTypeUnknown) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiFeedAdsSDKDomain code:MobiFeedAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate nativeExpressAdFailToLoadForAdManager:self error:error];
        return;
    }

    // 告诉服务器马上要加载广告了
//    [self.communicator sendBeforeLoadUrlWithConfiguration:configuration];

    // 开始加载计时
    [self.loadStopwatch start];

    MobiFeedAdapter *adapter = [[MobiFeedAdapter alloc] initWithDelegate:self];

    if (adapter == nil) {
        // 提示应用未知错误
        NSError *error = [NSError errorWithDomain:MobiFeedAdsSDKDomain code:MobiFeedAdErrorUnknown userInfo:nil];
        [self.delegate nativeExpressAdFailToLoadForAdManager:self error:error];
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
        NSError * clearResponseError = [NSError errorWithDomain:MobiFeedAdsSDKDomain
                                                           code:MobiFeedAdErrorNoAdsAvailable
                                                       userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
//        MPLogAdEvent([MPLogEvent adFailedToLoadWithError:clearResponseError], self.adUnitId);
        [self.delegate nativeExpressAdFailToLoadForAdManager:self error:error];
    }
}

// MARK: - MobiAdConfigServerDelegate
/// 分配广告平台去展示广告
- (void)assignCofigurationToPlay:(NSArray<MobiConfig *> *)configurations targeting:(MobiAdTargeting *)targeting count:(NSInteger)count {
    self.remainingConfigurations = [configurations mutableCopy];
    
    // 将用户期望的 FeedSize 大小传入 configuration
    for (MobiConfig *config in self.remainingConfigurations) {
        config.feedSize = targeting.feedSize;
        config.count = self.count;
    }
    
    self.configuration = [self.remainingConfigurations removeFirst];

    //将信息流广告尺寸赋值给config，经config传递到custom event
//    self.configuration.feedSize = self.targeting.feedSize;
//    self.configuration.count = self.count;
    
    // 若分配的平台是自有平台,则在此请求新内容
    if ([self.configuration.adapterProvider isKindOfClass:NSClassFromString(@"MEMobipubAdapter")]) {
        [self loadAdWithURL:[MobiAdServerURLBuilder URLWithAdPosid:self.adUnitId targeting:self.targeting]];
        return;
    }

    // 若没拉回来广告配置,则可能是kAdTypeClear类型(暂时没广告)
    if (self.remainingConfigurations.count == 0 && self.configuration == nil) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiFeedAdsSDKDomain code:MobiFeedAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate nativeExpressAdFailToLoadForAdManager:self error:error];
        return;
    }

    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Request;
    model.st_t = AdLogAdType_Feed;
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
    //将信息流广告尺寸赋值给config，经config传递到custom event
    self.configuration.feedSize = self.targeting.feedSize;

    // 若没拉回来广告配置,则可能是kAdTypeClear类型(暂时没广告)
    if (self.remainingConfigurations.count == 0 && self.configuration == nil) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiFeedAdsSDKDomain code:MobiFeedAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate nativeExpressAdFailToLoadForAdManager:self error:error];
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


#pragma mark - MobiRewardedVideoAdapterDelegate
/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoadForAdapter:(MobiFeedAdapter *)adapter views:(NSArray<__kindof MobiNativeExpressFeedView *> *)views {
    self.remainingConfigurations = nil;
    self.ready = YES;
    self.loading = NO;
    
    // 记录该广告从开始加载,到加载完成的时长,并上报
    NSTimeInterval duration = [self.loadStopwatch stop];
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:MPAfterLoadResultAdLoaded];
    
    // 数组中新增信息流视图
    [self.nativeExpressFeedViews addObjectsFromArray:views];
    
    //    MPLogAdEvent(MPLogEvent.adDidLoad, self.adUnitId);
    [self.delegate nativeExpressAdSuccessToLoadForAdManager:self views:views];
}

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoadForAdapter:(MobiFeedAdapter *)adapter error:(NSError *)error {
    // 记录加载失败的时长,并在MobiAdConfigServer中判断选择合适URL上报失败日志
    NSTimeInterval duration = [self.loadStopwatch stop];
//    MPAfterLoadResult result = (error.isAdRequestTimedOutError ? MPAfterLoadResultTimeout : (adapter == nil ? MPAfterLoadResultMissingAdapter : MPAfterLoadResultError));
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:result];

    [self loadFailedOperationwithError:error];
}

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewRenderSuccessForAdManager:self views:nativeExpressAdView];
    
    // 更改广告展示的频率
    [StrategyFactory changeAdFrequencyWithSceneId:self.posid];
}

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewRenderFailForAdManager:self views:nativeExpressAdView];
}

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewExposureForAdManager:self views:nativeExpressAdView];
}

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewClickedForAdManager:self views:nativeExpressAdView];
}

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    self.ready = NO;
    
//    MPLogAdEvent(MPLogEvent.adDidDisappear, self.adUnitId);
    [self.delegate nativeExpressAdViewClosedForAdManager:self views:nativeExpressAdView];
}

/**
 * 当一个posid加载完的广告资源失效时(过期),回调此方法
 */
- (void)nativeExpressAdDidExpireForAdapter:(MobiFeedAdapter *)adapter {
    self.ready = NO;
    
//    MPLogAdEvent([MPLogEvent adExpiredWithTimeInterval:MPConstants.adsExpirationInterval], self.adUnitId);
    [self.delegate nativeExpressAdDidExpireForAdManager:self];
}

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewWillPresentScreenForAdManager:self views:nativeExpressAdView];
}

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewDidPresentScreenForAdManager:self views:nativeExpressAdView];
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewWillDissmissScreenForAdManager:self views:nativeExpressAdView];
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewDidDissmissScreenForAdManager:self views:nativeExpressAdView];
}

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackgroundForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewApplicationWillEnterBackgroundForAdManager:self views:nativeExpressAdView];
}

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdViewForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView playerStatusChanged:(MobiMediaPlayerStatus)status {
    [self.delegate nativeExpressAdViewForAdManager:self views:nativeExpressAdView playerStatusChanged:status];
}

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewWillPresentVideoVCForAdManager:self views:nativeExpressAdView];
}

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewDidPresentVideoVCForAdManager:self views:nativeExpressAdView];
}

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewWillDismissVideoVCForAdManager:self views:nativeExpressAdView];
}

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView {
    [self.delegate nativeExpressAdViewDidDismissVideoVCForAdManager:self views:nativeExpressAdView];
}

@end
