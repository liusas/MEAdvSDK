//
//  MobiSplashAdManager.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import "MobiSplashAdManager.h"
#import "MobiSplashAdapter.h"
#import "MobiAdConfigServer.h"
#import "MobiConfig.h"
#import "NSMutableArray+MPAdditions.h"
#import "NSDate+MPAdditions.h"
#import "NSError+MPAdditions.h"
#import "MPLogging.h"
#import "MPError.h"
#import "MPStopwatch.h"
#import "MobiSplashError.h"
#import "MobiAdServerURLBuilder.h"
#import "StrategyFactory.h"
#import "MELogTracker.h"

@interface MobiSplashAdManager ()<MobiAdConfigServerDelegate, MobiSplashAdapterDelegate>

@property (nonatomic, strong) MobiSplashAdapter *adapter;
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

@implementation MobiSplashAdManager

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiSplashAdManagerDelegate>)delegate {
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

// 加载开屏广告
- (void)loadSplashAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting {
    self.playedAd = NO;

    if (self.loading) {
        MPLogEvent([MPLogEvent error:NSError.adAlreadyLoading message:nil]);
        return;
    }
    
    // 这里设置userid会覆盖我们之前设置的userid,在其他广告展示时我们会用这个新的userid
    self.userId = userId;
    self.targeting = targeting;
    
    // 获取 MEConfig 类型的数组,其中包含具体平台的广告位 id 和响应 network 的 custom event 执行类
    NSArray *configurations = [[StrategyFactory sharedInstance] getConfigurationsWithAdType:MobiAdTypeSplash sceneId:self.posid];
    if (configurations.count) {
        [self assignCofigurationToPlay:configurations];
    } else {
        // 若分配失败,则提示错误
        NSString *errorDescription = [NSString stringWithFormat:@"assign network error"];
        NSError * clearResponseError = [NSError errorWithDomain:MobiSplashAdsSDKDomain
                                                           code:MobiSplashAdErrorUnknown
                                                       userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        [self.delegate splashAdFailToPresentForManager:self withError:clearResponseError];
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

- (void)presentSplashAdFromWindow:(UIWindow *)window {
//    MPLogAdEvent(MPLogEvent.adShowAttempt, self.adUnitId);
    // 若广告没准备好,则不展示
    if (!self.ready) {
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorNoAdReady userInfo:@{ NSLocalizedDescriptionKey: @"Splash ad view is not ready to be shown"}];
        //        MPLogInfo(@"%@ error: %@", NSStringFromSelector(_cmd), error.localizedDescription);
        [self.delegate splashAdFailToPresentForManager:self withError:error];
        return;
    }

//    // 若当前正在展示广告,则不展示这个广告,激励视频每次只能展示一个
    if (self.playedAd) {
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorAdAlreadyPlayed userInfo:@{ NSLocalizedDescriptionKey: @"Splash ad view is playing" }];
        [self.delegate splashAdFailToPresentForManager:self withError:error];
        return;
    }
    
    // 通过adapter调用custom event执行广告展示
    [self.adapter presentSplashFromWindow:window];
}

/**
 * 停止开屏广告
 */
- (void)stopSplashAdWithPosid:(NSString *)posid {
    if (self.loadStopwatch.isRunning) {
        [self.loadStopwatch stop];
    }
    
    self.ready = NO;
    self.loading = NO;
}

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
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorAdUnitWarmingUp userInfo:nil];
        [self.delegate splashAdFailToPresentForManager:self withError:error];
        return;
    }

    if (configuration.adType == MobiAdTypeUnknown) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate splashAdFailToPresentForManager:self withError:error];
        return;
    }

    // 告诉服务器马上要加载广告了
//    [self.communicator sendBeforeLoadUrlWithConfiguration:configuration];

    // 开始加载计时
    [self.loadStopwatch start];

    MobiSplashAdapter *adapter = [[MobiSplashAdapter alloc] initWithDelegate:self];

    if (adapter == nil) {
        // 提示应用未知错误
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorUnknown userInfo:nil];
        [self.delegate splashAdFailToPresentForManager:self withError:error];
        return;
    }

    self.adapter = adapter;
    // 让adapter找到合适的custom event请求拉取广告
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
        NSError * clearResponseError = [NSError errorWithDomain:MobiSplashAdsSDKDomain
                                                           code:MobiSplashAdErrorNoAdsAvailable
                                                       userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
//        MPLogAdEvent([MPLogEvent adFailedToLoadWithError:clearResponseError], self.adUnitId);
        [self.delegate splashAdFailToPresentForManager:self withError:error];
    }
}

// MARK: - MobiSplashAdapterDelegate
/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForAdapter:(MobiSplashAdapter *)splashAd {
    self.remainingConfigurations = nil;
    self.ready = YES;
    self.loading = NO;
    
    // 记录该广告从开始加载,到加载完成的时长,并上报
    NSTimeInterval duration = [self.loadStopwatch stop];
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:MPAfterLoadResultAdLoaded];
    
//    MPLogAdEvent(MPLogEvent.adDidLoad, self.adUnitId);
    [self.delegate splashAdDidLoadForManager:self];
}

- (void)splashAdDidClickSkipForAdapter:(MobiSplashAdapter *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidClickSkipForManager:)]) {
        [self.delegate splashAdDidClickSkipForManager:self];
    }
}

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForAdapter:(MobiSplashAdapter *)splashAd withError:(NSError *)error {
    // 记录加载失败的时长,并在MobiAdConfigServer中判断选择合适URL上报失败日志
    NSTimeInterval duration = [self.loadStopwatch stop];
//    MPAfterLoadResult result = (error.isAdRequestTimedOutError ? MPAfterLoadResultTimeout : (splashAd == nil ? MPAfterLoadResultMissingAdapter : MPAfterLoadResultError));
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:result];
    
    [self loadFailedOperationwithError:error];
}

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdApplicationWillEnterBackgroundForManager:self];
}

/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdSuccessPresentScreenForManager:self];
    // 更改广告展示的频率
    [StrategyFactory changeAdFrequencyWithSceneId:self.posid];
}

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdExposuredForManager:self];
}

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdClickedForManager:self];
}

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdWillClosedForManager:self];
}

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForAdapter:(MobiSplashAdapter *)splashAd {
    self.ready = NO;
    self.playedAd = YES;
    [self.delegate splashAdClosedForManager:self];
}

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpireForAdapter:(MobiSplashAdapter *)splashAd {
    self.ready = NO;
    [self.delegate splashAdDidExpireForManager:self];
}

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdWillPresentFullScreenModalForManager:self];
}

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdDidPresentFullScreenModalForManager:self];
}

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdWillDismissFullScreenModalForManager:self];
}

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd {
    [self.delegate splashAdDidDismissFullScreenModalForManager:self];
}

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdLifeTime:(NSUInteger)time {
    [self.delegate splashAdForManager:self lifeTime:time];
}


- (NSString *)splashAdUnitId {
    return self.adUnitId;
}

- (NSString *)splashUserId {
    return self.userId;
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
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate splashAdFailToPresentForManager:self withError:error];
        return;
    }

    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Request;
    model.st_t = AdLogAdType_Splash;
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
    
    // 若没拉回来广告配置,则可能是kAdTypeClear类型(暂时没广告)
    if (self.remainingConfigurations.count == 0 && self.configuration == nil) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate splashAdFailToPresentForManager:self withError:error];
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

@end
