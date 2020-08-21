//
//  MobiRewardedVideoAdManager.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import "MobiRewardedVideoAdManager.h"
#import "MobiRewardedVideoAdapter.h"
#import "MobiAdConfigServer.h"
#import "MobiConfig.h"
#import "NSMutableArray+MPAdditions.h"
#import "NSDate+MPAdditions.h"
#import "NSError+MPAdditions.h"
#import "MPStopwatch.h"
#import "MobiRewardedVideoError.h"
#import "MobiAdServerURLBuilder.h"

@interface MobiRewardedVideoAdManager ()<MobiAdConfigServerDelegate, MobiRewardedVideoAdapterDelegate>

@property (nonatomic, strong) MobiRewardedVideoAdapter *adapter;
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


@implementation MobiRewardedVideoAdManager


- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiRewardedVideoAdManagerDelegate>)delegate {
    if (self = [super init]) {
        _posid = [posid copy];
        _communicator = [[MobiAdConfigServer alloc] initWithDelegate:self];
        _delegate = delegate;
        _loadStopwatch = MPStopwatch.new;
    }

    return self;
}

- (void)dealloc {
    [_communicator cancel];
}

//- (NSArray *)availableRewards {
//    return self.configuration.availableRewards;
//}

//- (MobiRewardedVideoReward *)selectedReward {
//    return self.configuration.selectedReward;
//}

/**
 * 加载激励视频广告
 * @param userId 用户的唯一标识
 * @param targeting 精准广告投放的一些参数,可为空
 */
- (void)loadRewardedVideoAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting {
//    MPLogAdEvent(MPLogEvent.adLoadAttempt, self.posid);
    // 若视频广告已经准备好展示了,我们就告诉上层加载完毕;若当前ad manager正在展示视频广告,则继续请求视频广告资源
    if (self.ready && !self.playedAd) {
        // 若已经有广告了,就不需要再绑定userid了,因为有可能这个广告已经绑定了旧的userid.
        [self.delegate rewardedVideoDidLoadForAdManager:self];
    } else {
        // 这里设置userid会覆盖我们之前设置的userid,在其他广告展示时我们会用这个新的userid
        self.userId = userId;
        self.targeting = targeting;
        [self loadAdWithURL:[MobiAdServerURLBuilder URLWithAdPosid:self.posid targeting:targeting]];
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
 * @param reward 从`availableRewards`中选择的奖励,在用户完成视频观看时给予用户
 */
- (void)presentRewardedVideoAdFromViewController:(UIViewController *)viewController withReward:(MobiRewardedVideoReward *)reward {
//    MPLogAdEvent(MPLogEvent.adShowAttempt, self.adUnitId);

    // 若广告没准备好,则不展示
    if (!self.ready) {
        NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorNoAdReady userInfo:@{ NSLocalizedDescriptionKey: @"Rewarded video ad view is not ready to be shown"}];
//        MPLogInfo(@"%@ error: %@", NSStringFromSelector(_cmd), error.localizedDescription);
        [self.delegate rewardedVideoDidFailToPlayForAdManager:self error:error];
        return;
    }

    // 若当前正在展示广告,则不展示这个广告,激励视频每次只能展示一个
    if (self.playedAd) {
        NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorAdAlreadyPlayed userInfo:nil];
        [self.delegate rewardedVideoDidFailToPlayForAdManager:self error:error];
        return;
    }

    // 当参数reward为nil时,若奖励池只有一个reward奖励,则我们要默认返回这个reward奖励
//    if (reward == nil) {
//        if (self.availableRewards.count == 1) {
//            MobiRewardedVideoReward * defaultReward = self.availableRewards[0];
//            self.configuration.selectedReward = defaultReward;
//        } else {
//            // 若奖励池里有很多reward奖励,我们不能觉得返回哪个奖励,返回播放失败
//            NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorNoRewardSelected userInfo:nil];
//            [self.delegate rewardedVideoDidFailToPlayForAdManager:self error:error];
//            return;
//        }
//    } else {
//        // 判断reward奖励是否在availableRewards中,若不在,则播放失败
//        if (![self.availableRewards containsObject:reward]) {
//            NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorInvalidReward userInfo:nil];
//            [self.delegate rewardedVideoDidFailToPlayForAdManager:self error:error];
//            return;
//        } else {
//            // 奖励reward通过验证,设置为选中奖励
//            self.configuration.selectedReward = reward;
//        }
//    }

    // 通过adapter调用custom event执行广告展示
    [self.adapter presentRewardedVideoFromViewController:viewController];
}

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
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
        NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorAdUnitWarmingUp userInfo:nil];
        [self.delegate rewardedVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    if (configuration.adType == MobiAdTypeUnknown) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate rewardedVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    // 告诉服务器马上要加载广告了
//    [self.communicator sendBeforeLoadUrlWithConfiguration:configuration];

    // 开始加载计时
    [self.loadStopwatch start];

    MobiRewardedVideoAdapter *adapter = [[MobiRewardedVideoAdapter alloc] initWithDelegate:self];

    if (adapter == nil) {
        // 提示应用未知错误
        NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorUnknown userInfo:nil];
        [self rewardedVideoDidFailToLoadForAdapter:nil error:error];
        return;
    }

    self.adapter = adapter;
    // 让adapter找到合适的custom event请求拉取视频广告
    [self.adapter getAdWithConfiguration:configuration targeting:self.targeting];
}

// MARK: - MobiAdConfigServerDelegate
/// 请求服务器拉取广告配置成功的回调
- (void)communicatorDidReceiveAdConfigurations:(NSArray<MobiConfig *> *)configurations {
    self.remainingConfigurations = [configurations mutableCopy];
    self.configuration = [self.remainingConfigurations removeFirst];

    // There are no configurations to try. Consider this a clear response by the server.
    // 若没拉回来广告配置,则可能是kAdTypeClear类型(暂时没广告)
    if (self.remainingConfigurations.count == 0 && self.configuration == nil) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate rewardedVideoDidFailToLoadForAdManager:self error:error];
        return;
    }

    [self fetchAdWithConfiguration:self.configuration];
}

- (void)communicatorDidFailWithError:(NSError *)error {
    self.ready = NO;
    self.loading = NO;

    [self.delegate rewardedVideoDidFailToLoadForAdManager:self error:error];
}

- (BOOL)isFullscreenAd {
    return YES;
}

- (NSString *)adUnitId {
    return self.posid;
}


#pragma mark - MobiRewardedVideoAdapterDelegate
// adapter从custom event得到的回调,回传给manager
- (void)rewardedVideoDidLoadForAdapter:(MobiRewardedVideoAdapter *)adapter {
    self.remainingConfigurations = nil;
    self.ready = YES;
    self.loading = NO;

    // 记录该广告从开始加载,到加载完成的时长,并上报
    NSTimeInterval duration = [self.loadStopwatch stop];
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:MPAfterLoadResultAdLoaded];

//    MPLogAdEvent(MPLogEvent.adDidLoad, self.adUnitId);
    [self.delegate rewardedVideoDidLoadForAdManager:self];
}

- (void)rewardedVideoAdVideoDidLoadForAdapter:(MobiRewardedVideoAdapter *)adapter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoAdVideoDidLoadForAdManager:)]) {
        [self.delegate rewardedVideoAdVideoDidLoadForAdManager:self];
    }
}

- (void)rewardedVideoDidFailToLoadForAdapter:(MobiRewardedVideoAdapter *)adapter error:(NSError *)error {
    // 记录加载失败的时长,并在MobiAdConfigServer中判断选择合适URL上报失败日志
    NSTimeInterval duration = [self.loadStopwatch stop];
//    MPAfterLoadResult result = (error.isAdRequestTimedOutError ? MPAfterLoadResultTimeout : (adapter == nil ? MPAfterLoadResultMissingAdapter : MPAfterLoadResultError));
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.configuration adapterLoadDuration:duration adapterLoadResult:result];

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
        NSError * clearResponseError = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain
                                                           code:MobiRewardedVideoAdErrorNoAdsAvailable
                                                       userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        //        MPLogAdEvent([MPLogEvent adFailedToLoadWithError:clearResponseError], self.adUnitId);
        [self.delegate rewardedVideoDidFailToLoadForAdManager:self error:error];
    }
}

- (void)rewardedVideoDidExpireForAdapter:(MobiRewardedVideoAdapter *)adapter {
    self.ready = NO;

//    MPLogAdEvent([MPLogEvent adExpiredWithTimeInterval:MPConstants.adsExpirationInterval], self.adUnitId);
    [self.delegate rewardedVideoDidExpireForAdManager:self];
}

- (void)rewardedVideoDidFailToPlayForAdapter:(MobiRewardedVideoAdapter *)adapter error:(NSError *)error {
    // 若视频播放失败,则立即重置激励视频状态,保证下一个广告可以正常播放
    self.ready = NO;
    self.playedAd = NO;

//    MPLogAdEvent([MPLogEvent adShowFailedWithError:error], self.adUnitId);
    [self.delegate rewardedVideoDidFailToPlayForAdManager:self error:error];
}

- (void)rewardedVideoWillAppearForAdapter:(MobiRewardedVideoAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillAppear, self.adUnitId);
    [self.delegate rewardedVideoWillAppearForAdManager:self];
}

- (void)rewardedVideoDidAppearForAdapter:(MobiRewardedVideoAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adDidAppear, self.adUnitId);
    [self.delegate rewardedVideoDidAppearForAdManager:self];
}

- (void)rewardedVideoWillDisappearForAdapter:(MobiRewardedVideoAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillDisappear, self.adUnitId);
    [self.delegate rewardedVideoWillDisappearForAdManager:self];
}

- (void)rewardedVideoDidDisappearForAdapter:(MobiRewardedVideoAdapter *)adapter {
    // Successful playback of the rewarded video; reset the internal played state.
    self.ready = NO;
    self.playedAd = YES;

//    MPLogAdEvent(MPLogEvent.adDidDisappear, self.adUnitId);
    [self.delegate rewardedVideoDidDisappearForAdManager:self];
}

- (void)rewardedVideoDidReceiveTapEventForAdapter:(MobiRewardedVideoAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillPresentModal, self.adUnitId);
    [self.delegate rewardedVideoDidReceiveTapEventForAdManager:self];
}

- (void)rewardedVideoDidReceiveImpressionEventForAdapter:(MobiRewardedVideoAdapter *)adapter {
//    [self.delegate rewardedVideoAdManager:self didReceiveImpressionEventWithImpressionData:self.configuration.impressionData];
}

- (void)rewardedVideoWillLeaveApplicationForAdapter:(MobiRewardedVideoAdapter *)adapter {
//    MPLogAdEvent(MPLogEvent.adWillLeaveApplication, self.adUnitId);
    [self.delegate rewardedVideoWillLeaveApplicationForAdManager:self];
}

- (void)rewardedVideoShouldRewardUserForAdapter:(MobiRewardedVideoAdapter *)adapter reward:(MobiRewardedVideoReward *)reward {
//    MPLogAdEvent([MPLogEvent adShouldRewardUserWithReward:reward], self.adUnitId);
    [self.delegate rewardedVideoShouldRewardUserForAdManager:self reward:reward];
}

- (NSString *)rewardedVideoAdUnitId {
    return self.adUnitId;
}

- (NSString *)rewardedVideoCustomerId {
    return self.userId;
}

@end
