//
//  MPInterstitialAdManager.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <objc/runtime.h>

#import "MPInterstitialAdManager.h"

#import "MobiAdServerURLBuilder.h"
#import "MobiAdTargeting.h"
#import "MPInterstitialAdController.h"
#import "MPInterstitialCustomEventAdapter.h"
#import "MPConstants.h"
#import "MPCoreInstanceProvider.h"
#import "MPInterstitialAdManagerDelegate.h"
#import "MPLogging.h"
#import "MPError.h"
#import "MPStopwatch.h"
#import "NSMutableArray+MPAdditions.h"
#import "NSDate+MPAdditions.h"
#import "NSError+MPAdditions.h"
#import "MobiInterstitialError.h"

#import "StrategyFactory.h"
#import "MELogTracker.h"

@interface MPInterstitialAdManager ()

@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign, readwrite) BOOL ready;
@property (nonatomic, strong) MPBaseInterstitialAdapter *adapter;
@property (nonatomic, strong) MobiAdConfigServer *communicator;
@property (nonatomic, strong) MobiConfig *requestingConfiguration;
@property (nonatomic, strong) NSMutableArray<MobiConfig *> *remainingConfigurations;
@property (nonatomic, strong) MPStopwatch *loadStopwatch;
@property (nonatomic, strong) MobiAdTargeting * targeting;
@property (nonatomic, strong) NSURL *mostRecentlyLoadedURL;  // ADF-4286: avoid infinite ad reloads

- (void)setUpAdapterWithConfiguration:(MobiConfig *)configuration;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPInterstitialAdManager

- (id)initWithDelegate:(id<MPInterstitialAdManagerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.communicator = [[MobiAdConfigServer alloc] initWithDelegate:self];
        self.delegate = delegate;

        _loadStopwatch = MPStopwatch.new;
    }
    return self;
}

- (void)dealloc
{
    [self.communicator cancel];
    [self.communicator setDelegate:nil];

    self.adapter = nil;
}

- (void)setAdapter:(MPBaseInterstitialAdapter *)adapter
{
    if (self.adapter != adapter) {
        [self.adapter unregisterDelegate];
        _adapter = adapter;
    }
}

#pragma mark - Public

- (void)loadAdWithURL:(NSURL *)URL
{
    if (self.loading) {
        MPLogEvent([MPLogEvent error:NSError.adAlreadyLoading message:nil]);
        return;
    }

    self.loading = YES;
    self.mostRecentlyLoadedURL = URL;
    [self.communicator loadURL:URL];
}


- (void)loadInterstitialWithAdUnitID:(NSString *)ID targeting:(MobiAdTargeting *)targeting
{
    MPLogAdEvent(MPLogEvent.adLoadAttempt, ID);

    if (self.loading) {
        MPLogEvent([MPLogEvent error:NSError.adAlreadyLoading message:nil]);
        return;
    }
    
    if (self.ready) {
        [self.delegate managerDidLoadInterstitial:self];
    } else {
        self.targeting = targeting;
        
        // 获取 MEConfig 类型的数组,其中包含具体平台的广告位 id 和响应 network 的 custom event 执行类
        NSArray *configurations = [[StrategyFactory sharedInstance] getConfigurationsWithAdType:MobiAdTypeInterstitial sceneId:self.adUnitId];
        if (configurations.count) {
            [self assignCofigurationToPlay:configurations];
        } else {
            // 若分配失败,则提示错误
            NSString *errorDescription = [NSString stringWithFormat:@"assign network error"];
            NSError * clearResponseError = [NSError errorWithDomain:MobiInterstitialAdsSDKDomain
                                                               code:MobiInterstitialAdErrorUnknown
                                                           userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
            [self.delegate manager:self didFailToLoadInterstitialWithError:clearResponseError];
        }
    }
}

- (void)presentInterstitialFromViewController:(UIViewController *)controller
{
    MPLogAdEvent(MPLogEvent.adShowAttempt, self.delegate.interstitialAdController.adUnitId);

    // Don't allow the ad to be shown if it isn't ready.
    if (!self.ready) {
        MPLogInfo(@"Interstitial ad view is not ready to be shown");
        return;
    }

    [self.adapter showInterstitialFromViewController:controller];
}

- (CLLocation *)location
{
    return [self.delegate location];
}

- (MPInterstitialAdController *)interstitialAdController
{
    return [self.delegate interstitialAdController];
}

- (id)interstitialDelegate
{
    return [self.delegate interstitialDelegate];
}

#pragma mark - Private
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
//    else if (self.requestingConfiguration.nextURL != nil
//             && [self.requestingConfiguration.nextURL isEqual:self.mostRecentlyLoadedURL] == false) {
//        self.ready = NO;
//        self.loading = NO;
//        [self loadAdWithURL:self.requestingConfiguration.nextURL];
//    }
    // No more configurations to try and no more pages to load.
    else {
        self.ready = NO;
        self.loading = NO;

        NSError * clearResponseError = [NSError errorWithCode:MOPUBErrorNoInventory localizedDescription:[NSString stringWithFormat:kMPClearErrorLogFormatWithAdUnitID, self.delegate.interstitialAdController.adUnitId]];
        MPLogAdEvent([MPLogEvent adFailedToLoadWithError:clearResponseError], self.delegate.interstitialAdController.adUnitId);
        [self.delegate manager:self didFailToLoadInterstitialWithError:clearResponseError];
    }
}

- (void)fetchAdWithConfiguration:(MobiConfig *)configuration
{
//    MPLogInfo(@"Interstitial ad view is fetching ad type: %@", configuration.adType);

    if (configuration.adUnitWarmingUp) {
        MPLogInfo(kMPWarmingUpErrorLogFormatWithAdUnitID, self.delegate.interstitialAdController.adUnitId);
        self.loading = NO;
        [self.delegate manager:self didFailToLoadInterstitialWithError:[NSError errorWithCode:MOPUBErrorAdUnitWarmingUp]];
        return;
    }

//    if ([configuration.adType isEqualToString:kAdTypeClear]) {
//        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.delegate.interstitialAdController.adUnitId);
//        self.loading = NO;
//        [self.delegate manager:self didFailToLoadInterstitialWithError:[NSError errorWithCode:MOPUBErrorNoInventory]];
//        return;
//    }

    [self setUpAdapterWithConfiguration:configuration];
}

- (void)setUpAdapterWithConfiguration:(MobiConfig *)configuration
{
    // Notify Ad Server of the adapter load. This is fire and forget.
//    [self.communicator sendBeforeLoadUrlWithConfiguration:configuration];

    // Start the stopwatch for the adapter load.
    [self.loadStopwatch start];

    if (configuration.customEventClass == nil) {
        [self adapter:nil didFailToLoadAdWithError:nil];
        return;
    }

    MPBaseInterstitialAdapter *adapter = [[MPInterstitialCustomEventAdapter alloc] initWithDelegate:self];
    self.adapter = adapter;
    [self.adapter _getAdWithConfiguration:configuration targeting:self.targeting];
}

#pragma mark - MobiAdConfigServerDelegate
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
        self.loading = NO;
        NSError *error = [NSError errorWithDomain:MobiInterstitialAdsSDKDomain code:MobiInterstitialAdErrorNoAdsAvailable userInfo:nil];
        [self.delegate manager:self didFailToLoadInterstitialWithError:error];
        return;
    }

    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Request;
    model.st_t = AdLogAdType_Interstitial;
    model.so_t = self.requestingConfiguration.sortType;
    model.posid = self.requestingConfiguration.adUnitId;
    model.network = self.requestingConfiguration.networkName;
    model.nt_name = self.requestingConfiguration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
    
    [self fetchAdWithConfiguration:self.requestingConfiguration];
}


- (void)communicatorDidReceiveAdConfigurations:(NSArray<MobiConfig *> *)configurations {
    for (MobiConfig *object in [configurations reverseObjectEnumerator]) {
        [self.remainingConfigurations insertObject:object atIndex:0];
    }
    
    self.requestingConfiguration = [self.remainingConfigurations removeFirst];

    // There are no configurations to try. Consider this a clear response by the server.
    if (self.remainingConfigurations.count == 0 && self.requestingConfiguration == nil) {
        MPLogInfo(kMPClearErrorLogFormatWithAdUnitID, self.delegate.interstitialAdController.adUnitId);
        self.loading = NO;
        [self.delegate manager:self didFailToLoadInterstitialWithError:[NSError errorWithCode:MOPUBErrorNoInventory]];
        return;
    }

    [self fetchAdWithConfiguration:self.requestingConfiguration];
}

- (void)communicatorDidFailWithError:(NSError *)error {
    [self loadFailedOperationwithError:error];
}

- (BOOL)isFullscreenAd {
    return YES;
}

- (NSString *)adUnitId {
    return [self.delegate adUnitId];
}

#pragma mark - MPInterstitialAdapterDelegate

- (void)adapterDidFinishLoadingAd:(MPBaseInterstitialAdapter *)adapter
{
    self.remainingConfigurations = nil;
    self.ready = YES;
    self.loading = NO;

    // Record the end of the adapter load and send off the fire and forget after-load-url tracker.
    NSTimeInterval duration = [self.loadStopwatch stop];
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.requestingConfiguration adapterLoadDuration:duration adapterLoadResult:MPAfterLoadResultAdLoaded];

    MPLogAdEvent(MPLogEvent.adDidLoad, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerDidLoadInterstitial:self];
}

- (void)adapter:(MPBaseInterstitialAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
    // Record the end of the adapter load and send off the fire and forget after-load-url tracker
    // with the appropriate error code result.
    NSTimeInterval duration = [self.loadStopwatch stop];
//    MPAfterLoadResult result = (error.isAdRequestTimedOutError ? MPAfterLoadResultTimeout : (adapter == nil ? MPAfterLoadResultMissingAdapter : MPAfterLoadResultError));
//    [self.communicator sendAfterLoadUrlWithConfiguration:self.requestingConfiguration adapterLoadDuration:duration adapterLoadResult:result];

    [self loadFailedOperationwithError:error];
}

- (void)interstitialWillAppearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    MPLogAdEvent(MPLogEvent.adWillAppear, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerWillPresentInterstitial:self];
    
    // 更改广告展示的频率
    [StrategyFactory changeAdFrequencyWithSceneId:self.adUnitId];
}

- (void)interstitialDidAppearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    MPLogAdEvent(MPLogEvent.adDidAppear, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerDidPresentInterstitial:self];
}

- (void)interstitialWillDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    MPLogAdEvent(MPLogEvent.adWillDisappear, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerWillDismissInterstitial:self];
}

- (void)interstitialDidDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    self.ready = NO;

    MPLogAdEvent(MPLogEvent.adDidDisappear, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerDidDismissInterstitial:self];
}

- (void)interstitialWillPresentModalForAdapter:(MPBaseInterstitialAdapter *)adapter {
    MPLogAdEvent(MPLogEvent.adWillPresentModal, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerWillPresentModal:self];
}

- (void)interstitialDidDismissModalForAdapter:(MPBaseInterstitialAdapter *)adapter {
    MPLogAdEvent(MPLogEvent.adDidDismissModal, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerDidDismissModal:self];
}

- (void)interstitialDidExpireForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    self.ready = NO;

    MPLogAdEvent([MPLogEvent adExpiredWithTimeInterval:MPConstants.adsExpirationInterval], self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerDidExpireInterstitial:self];
}

- (void)interstitialDidReceiveTapEventForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    MPLogAdEvent(MPLogEvent.adWillPresentModal, self.delegate.interstitialAdController.adUnitId);
    [self.delegate managerDidReceiveTapEventFromInterstitial:self];
}

- (void)interstitialWillLeaveApplicationForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    MPLogAdEvent(MPLogEvent.adWillLeaveApplication, self.delegate.interstitialAdController.adUnitId);
}

- (void)interstitialDidReceiveImpressionEventForAdapter:(MPBaseInterstitialAdapter *)adapter {
//    [self.delegate interstitialAdManager:self didReceiveImpressionEventWithImpressionData:self.requestingConfiguration.impressionData];
}

@end
