//
//  MPBannerAdManager.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPBannerAdManager.h"
#import "MobiAdServerURLBuilder.h"
#import "MobiAdTargeting.h"
#import "MPCoreInstanceProvider.h"
#import "MPBannerAdManagerDelegate.h"
#import "MPError.h"
#import "MobiTimer.h"
#import "MPConstants.h"
#import "MPLogging.h"
#import "MPStopwatch.h"
#import "MPBannerCustomEventAdapter.h"
#import "NSMutableArray+MPAdditions.h"
#import "NSDate+MPAdditions.h"
#import "NSError+MPAdditions.h"
#import "StrategyFactory.h"
#import "MobiBannerError.h"

@interface MPBannerAdManager ()

@property (nonatomic, strong) MobiAdConfigServer *communicator;
@property (nonatomic, strong) MPBaseBannerAdapter *onscreenAdapter;
@property (nonatomic, strong) MPBaseBannerAdapter *requestingAdapter;
@property (nonatomic, strong) UIView *requestingAdapterAdContentView;
@property (nonatomic, strong) MobiConfig *requestingConfiguration;
@property (nonatomic, strong) MobiAdTargeting *targeting;
@property (nonatomic, strong) NSMutableArray<MobiConfig *> *remainingConfigurations;
@property (nonatomic, strong) MobiTimer *refreshTimer;
@property (nonatomic, strong) NSURL *mostRecentlyLoadedURL; // ADF-4286: avoid infinite ad reloads
@property (nonatomic, assign) BOOL adActionInProgress;
@property (nonatomic, assign) BOOL automaticallyRefreshesContents;
@property (nonatomic, assign) BOOL hasRequestedAtLeastOneAd;
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation;
@property (nonatomic, strong) MPStopwatch *loadStopwatch;

- (void)loadAdWithURL:(NSURL *)URL;
- (void)applicationWillEnterForeground;
- (void)scheduleRefreshTimer;
- (void)refreshTimerDidFire;

@end

@implementation MPBannerAdManager

- (id)initWithDelegate:(id<MPBannerAdManagerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;

        self.communicator = [[MobiAdConfigServer alloc] initWithDelegate:self];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:[UIApplication sharedApplication]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];

        self.automaticallyRefreshesContents = YES;
        self.currentOrientation = MPInterfaceOrientation();
        _remainingConfigurations = [NSMutableArray array];
//        _loadStopwatch = MPStopwatch.new;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.communicator cancel];
    [self.communicator setDelegate:nil];

    [self.refreshTimer invalidate];

    [self.onscreenAdapter unregisterDelegate];

    [self.requestingAdapter unregisterDelegate];

}

- (BOOL)loading
{
    return self.communicator.loading || self.requestingAdapter;
}

- (void)loadAdWithTargeting:(MobiAdTargeting *)targeting
{
    MPLogAdEvent(MPLogEvent.adLoadAttempt, self.delegate.adUnitId);

    if (!self.hasRequestedAtLeastOneAd) {
        self.hasRequestedAtLeastOneAd = YES;
    }

    if (self.loading) {
        MPLogEvent([MPLogEvent error:NSError.adAlreadyLoading message:nil]);
        return;
    }

    self.targeting = targeting;
//    [self loadAdWithURL:nil];
    // 获取 MEConfig 类型的数组,其中包含具体平台的广告位 id 和响应 network 的 custom event 执行类
    NSArray *configurations = [[StrategyFactory sharedInstance] getConfigurationsWithAdType:MobiAdTypeBanner sceneId:self.adUnitId];
    if (configurations.count) {
        [self assignCofigurationToPlay:configurations];
    } else {
        // 若分配失败,则提示错误
        NSString *errorDescription = [NSString stringWithFormat:@"assign network error"];
        NSError * clearResponseError = [NSError errorWithDomain:MobiBannerAdsSDKDomain
                                                           code:MobiBannerAdErrorNoAdsAvailable
                                                       userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        [self.delegate managerDidFailToLoadAdWithError:clearResponseError];
    }
}

- (void)forceRefreshAd
{
    [self loadAdWithURL:nil];
}

- (void)applicationWillEnterForeground
{
    if (self.automaticallyRefreshesContents && self.hasRequestedAtLeastOneAd) {
        [self loadAdWithURL:nil];
    }
}

- (void)applicationDidEnterBackground
{
    [self pauseRefreshTimer];
}

- (void)pauseRefreshTimer
{
    if ([self.refreshTimer isValid]) {
        [self.refreshTimer pause];
    }
}

- (void)resumeRefreshTimer
{
    if ([self.refreshTimer isValid]) {
        [self.refreshTimer resume];
    }
}

- (void)stopAutomaticallyRefreshingContents
{
    self.automaticallyRefreshesContents = NO;

    [self pauseRefreshTimer];
}

- (void)startAutomaticallyRefreshingContents
{
    self.automaticallyRefreshesContents = YES;

    if ([self.refreshTimer isValid]) {
        [self.refreshTimer resume];
    } else if (self.refreshTimer) {
        [self scheduleRefreshTimer];
    }
}

- (void)loadAdWithURL:(NSURL *)URL
{
    URL = [URL copy]; //if this is the URL from the requestingConfiguration, it's about to die...
    // Cancel the current request/requesting adapter
    self.requestingConfiguration = nil;
    [self.requestingAdapter unregisterDelegate];
    self.requestingAdapter = nil;
    self.requestingAdapterAdContentView = nil;

    [self.communicator cancel];

    URL = (URL) ? URL : [MobiAdServerURLBuilder URLWithAdPosid:[self.delegate adUnitId] targeting:self.targeting];

    self.mostRecentlyLoadedURL = URL;

    [self.communicator loadURL:URL];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation
{
    self.currentOrientation = orientation;
    [self.requestingAdapter rotateToOrientation:orientation];
    [self.onscreenAdapter rotateToOrientation:orientation];
}

- (BOOL)isMraidAd
{
    if (self.requestingConfiguration.bannerConfigData.fw == 5) {
        // 是 Mraid 协议广告
        return YES;
    }
    return NO;
}

#pragma mark - Internal

- (void)scheduleRefreshTimer
{
    [self.refreshTimer invalidate];
    NSTimeInterval timeInterval = self.requestingConfiguration ? self.requestingConfiguration.refreshInterval : DEFAULT_BANNER_REFRESH_INTERVAL;

    if (self.automaticallyRefreshesContents && timeInterval > 0) {
        self.refreshTimer = [MobiTimer timerWithTimeInterval:timeInterval
                                                    target:self
                                                  selector:@selector(refreshTimerDidFire)
                                                   repeats:NO];
        [self.refreshTimer scheduleNow];
        MPLogDebug(@"Scheduled the autorefresh timer to fire in %.1f seconds (%p).", timeInterval, self.refreshTimer);
    }
}

- (void)refreshTimerDidFire
{
    if (!self.loading) {
        // Instead of reusing the existing `MobiAdTargeting` that is potentially outdated, ask the
        // delegate to provide the `MobiAdTargeting` so that it's the latest.
        [self loadAdWithTargeting:self.delegate.adTargeting];
    }
}

- (void)fetchAdWithConfiguration:(MobiConfig *)configuration {
//    MPLogInfo(@"Banner ad view is fetching ad type: %@", configuration.adType);

    if (configuration.adUnitWarmingUp) {
        MPLogInfo(kMPWarmingUpErrorLogFormatWithAdUnitID, self.delegate.adUnitId);
        [self didFailToLoadAdapterWithError:[NSError errorWithCode:MOPUBErrorAdUnitWarmingUp]];
        return;
    }

//    if ([configuration.adType isEqualToString:kAdTypeClear]) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.delegate.adUnitId);
//        [self didFailToLoadAdapterWithError:[NSError errorWithCode:MOPUBErrorNoInventory]];
//        return;
//    }

    // Notify Ad Server of the ad fetch attempt. This is fire and forget.
//    [self.communicator sendBeforeLoadUrlWithConfiguration:configuration];

    // Start the stopwatch for the adapter load.
//    [self.loadStopwatch start];

    self.requestingAdapter = [[MPBannerCustomEventAdapter alloc] initWithConfiguration:configuration
                                                                              delegate:self];
    if (self.requestingAdapter == nil) {
        [self adapter:nil didFailToLoadAdWithError:nil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.requestingAdapter _getAdWithConfiguration:configuration targeting:self.targeting containerSize:self.delegate.containerSize];
    });
}

/// 加载失败后的统一处理,需要查看是否有备用广告平台可选
- (void)loadFailedOperationwithError:(NSError *)error {
    if (self.loadStopwatch.isRunning) {
        [self.loadStopwatch stop];
    }
    
    // There are more ad configurations to try.
    if (self.remainingConfigurations.count > 0) {
        self.requestingConfiguration = [self.remainingConfigurations removeFirst];
        [self fetchAdWithConfiguration:self.requestingConfiguration];
    }
    // No more configurations to try. Send new request to Ads server to get more Ads.
//        else if (self.requestingConfiguration.nextURL != nil
//                 && [self.requestingConfiguration.nextURL isEqual:self.mostRecentlyLoadedURL] == false) {
//            [self loadAdWithURL:self.requestingConfiguration.nextURL];
//        }
    // No more configurations to try and no more pages to load.
    else {
        NSError * clearResponseError = [NSError errorWithCode:MOPUBErrorNoInventory localizedDescription:[NSString stringWithFormat:kMPClearErrorLogFormatWithAdUnitID, self.delegate.banner.adUnitId]];
        MPLogAdEvent([MPLogEvent adFailedToLoadWithError:clearResponseError], self.delegate.banner.adUnitId);
        [self didFailToLoadAdapterWithError:clearResponseError];
    }
}

#pragma mark - <MobiAdConfigServerDelegate>
/// 分配广告平台去展示广告
- (void)assignCofigurationToPlay:(NSArray<MobiConfig *> *)configurations {
    self.remainingConfigurations = [configurations mutableCopy];
    self.requestingConfiguration = [self.remainingConfigurations removeFirst];

    
    // 若分配的平台是自有平台,则在此请求新内容
    if ([self.requestingConfiguration.adapterProvider isKindOfClass:NSClassFromString(@"MEMobipubAdapter")]) {
        [self loadAdWithURL:[MobiAdServerURLBuilder URLWithAdPosid:self.adUnitId targeting:self.targeting]];
        return;
    }

    // 若没拉回来广告配置,则可能是kAdTypeClear类型(暂时没广告)
    if (self.remainingConfigurations.count == 0 && self.requestingConfiguration == nil) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.adUnitId);
        NSError *error = [NSError errorWithDomain:MobiBannerAdsSDKDomain code:MobiBannerAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate managerDidFailToLoadAdWithError:error];
        return;
    }

    [self fetchAdWithConfiguration:self.requestingConfiguration];
}


- (void)communicatorDidReceiveAdConfigurations:(NSArray<MobiConfig *> *)configurations
{
    self.remainingConfigurations = [configurations mutableCopy];
    self.requestingConfiguration = [self.remainingConfigurations removeFirst];

    // There are no configurations to try. Consider this a clear response by the server.
    if (self.remainingConfigurations.count == 0 && self.requestingConfiguration == nil) {
        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.delegate.adUnitId);
        [self didFailToLoadAdapterWithError:[NSError errorWithCode:MOPUBErrorNoInventory]];
        return;
    }

    [self fetchAdWithConfiguration:self.requestingConfiguration];
}

- (void)communicatorDidFailWithError:(NSError *)error
{
    [self loadFailedOperationwithError:error];
}

- (void)didFailToLoadAdapterWithError:(NSError *)error
{
    [self.delegate managerDidFailToLoadAdWithError:error];
    [self scheduleRefreshTimer];
}

- (BOOL)isFullscreenAd {
    return NO;
}

- (NSString *)adUnitId {
    return [self.delegate adUnitId];
}

#pragma mark - <MPBannerAdapterDelegate>

- (MPAdView *)banner
{
    return [self.delegate banner];
}

- (id<MPAdViewDelegate>)bannerDelegate
{
    return [self.delegate bannerDelegate];
}

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (MPNativeAdOrientation)allowedNativeAdsOrientation
{
    return [self.delegate allowedNativeAdsOrientation];
}

- (CLLocation *)location
{
    return nil;
}

- (NSString *)networkName {
    return self.requestingConfiguration.networkName;
}

- (NSInteger)sortType {
    return self.requestingConfiguration.sortType;
}


- (BOOL)requestingAdapterIsReadyToBePresented
{
    return !!self.requestingAdapterAdContentView;
}

- (void)presentRequestingAdapter
{
    if (!self.adActionInProgress && self.requestingAdapterIsReadyToBePresented) {
        [self.onscreenAdapter unregisterDelegate];
        self.onscreenAdapter = self.requestingAdapter;
        self.requestingAdapter = nil;

        [self.onscreenAdapter rotateToOrientation:self.currentOrientation];
        [self.delegate managerDidLoadAd:self.requestingAdapterAdContentView];
        [self.onscreenAdapter didDisplayAd];

        self.requestingAdapterAdContentView = nil;
    }
}

- (void)adapter:(MPBaseBannerAdapter *)adapter didFinishLoadingAd:(UIView *)ad
{
    if (self.requestingAdapter == adapter) {
        self.remainingConfigurations = nil;
        self.requestingAdapterAdContentView = ad;

        // Record the end of the adapter load and send off the fire and forget after-load-url tracker.
//        NSTimeInterval duration = [self.loadStopwatch stop];
//        [self.communicator sendAfterLoadUrlWithConfiguration:self.requestingConfiguration adapterLoadDuration:duration adapterLoadResult:MPAfterLoadResultAdLoaded];

        MPLogAdEvent(MPLogEvent.adDidLoad, self.delegate.banner.adUnitId);
        [self presentRequestingAdapter];
    }
}

- (void)adapter:(MPBaseBannerAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
    // Record the end of the adapter load and send off the fire and forget after-load-url tracker
    // with the appropriate error code result.
//    NSTimeInterval duration = [self.loadStopwatch stop];
//    MPAfterLoadResult result = (error.isAdRequestTimedOutError ? MPAfterLoadResultTimeout : (adapter == nil ? MPAfterLoadResultMissingAdapter : MPAfterLoadResultError));
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.requestingConfiguration adapterLoadDuration:duration adapterLoadResult:result];

    if (self.requestingAdapter == adapter) {
        [self loadFailedOperationwithError:error];
    }

    if (self.onscreenAdapter == adapter && adapter != nil) {
        // the onscreen adapter has failed.  we need to:
        // 1) remove it
        // 2) and note that there can't possibly be a modal on display any more
        [self.delegate invalidateContentView];
        [self.onscreenAdapter unregisterDelegate];
        self.onscreenAdapter = nil;
        if (self.adActionInProgress) {
            [self.delegate userActionDidFinish];
            self.adActionInProgress = NO;
        }
        if (self.requestingAdapterIsReadyToBePresented) {
            [self presentRequestingAdapter];
        } else {
            [self loadAdWithTargeting:self.targeting];
        }
    }
}

- (void)adapterDidTrackImpressionForAd:(MPBaseBannerAdapter *)adapter {
    if (self.onscreenAdapter == adapter) {
        [self scheduleRefreshTimer];
    }

//    [self.delegate impressionDidFireWithImpressionData:self.requestingConfiguration.impressionData];
}

- (void)userActionWillBeginForAdapter:(MPBaseBannerAdapter *)adapter
{
    if (self.onscreenAdapter == adapter) {
        self.adActionInProgress = YES;

        MPLogAdEvent(MPLogEvent.adTapped, self.delegate.banner.adUnitId);
        MPLogAdEvent(MPLogEvent.adWillPresentModal, self.delegate.banner.adUnitId);
        [self.delegate userActionWillBegin];
    }
}

- (void)userActionDidFinishForAdapter:(MPBaseBannerAdapter *)adapter
{
    if (self.onscreenAdapter == adapter) {
        MPLogAdEvent(MPLogEvent.adDidDismissModal, self.delegate.banner.adUnitId);
        [self.delegate userActionDidFinish];

        self.adActionInProgress = NO;
        [self presentRequestingAdapter];
    }
}

- (void)userWillLeaveApplicationFromAdapter:(MPBaseBannerAdapter *)adapter
{
    if (self.onscreenAdapter == adapter) {
        MPLogAdEvent(MPLogEvent.adTapped, self.delegate.banner.adUnitId);
        MPLogAdEvent(MPLogEvent.adWillLeaveApplication, self.delegate.banner.adUnitId);
        [self.delegate userWillLeaveApplication];
    }
}

- (void)adapter:(MPBaseBannerAdapter *)adapter WillVisible:(UIView *)ad {
    // 更改广告展示的频率
    [StrategyFactory changeAdFrequencyWithSceneId:self.adUnitId];
    
    if (self.onscreenAdapter == adapter) {
        [self.delegate managerAdWillVisible:ad];
    }
}

- (void)adapter:(MPBaseBannerAdapter *)adapter AdDidClick:(UIView *)ad {
    if (self.onscreenAdapter == adapter) {
        [self.delegate managerAdDidClick:ad];
    }
}

- (void)adapter:(MPBaseBannerAdapter *)adapter AdViewWillClose:(UIView *)ad {
    if (self.onscreenAdapter == adapter) {
        [self.delegate adViewWillClose:ad];
    }
}

- (void)adWillExpandForAdapter:(MPBaseBannerAdapter *)adapter
{
    // While the banner ad is in an expanded state, the refresh timer should be paused
    // since the user is interacting with the ad experience.
    [self pauseRefreshTimer];
}

- (void)adDidCollapseForAdapter:(MPBaseBannerAdapter *)adapter
{
    // Once the banner ad is collapsed back into its default state, the refresh timer
    // should be resumed to queue up the next ad.
    [self resumeRefreshTimer];
}

@end

