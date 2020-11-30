//
//  MPBannerCustomEventAdapter.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPBannerCustomEventAdapter.h"

#import "MobiConfig.h"
#import "MobiAdTargeting.h"
#import "MPBannerCustomEvent.h"
#import "MPCoreInstanceProvider.h"
#import "MPError.h"
#import "MPLogging.h"
#import "MPAdImpressionTimer.h"
#import "MPBannerCustomEvent+Internal.h"
#import "MELogTracker.h"

static CGFloat const kDefaultRequiredPixelsInViewForImpression         = 1.0;
static NSTimeInterval const kDefaultRequiredSecondsInViewForImpression = 0.0;

@interface MPBannerCustomEventAdapter () <MPAdImpressionTimerDelegate>

@property (nonatomic, strong) MPBannerCustomEvent *bannerCustomEvent;
@property (nonatomic, strong) MobiConfig *configuration;
@property (nonatomic, assign) BOOL hasTrackedImpression;
@property (nonatomic, assign) BOOL hasTrackedClick;
@property (nonatomic) MPAdImpressionTimer *impressionTimer;
@property (nonatomic) UIView *adView;

- (void)trackClickOnce;

@end

@implementation MPBannerCustomEventAdapter

- (instancetype)initWithConfiguration:(MobiConfig *)configuration delegate:(id<MPBannerAdapterDelegate>)delegate
{
    if (!configuration.customEventClass) {
        return nil;
    }
    return [self initWithDelegate:delegate];
}

- (void)unregisterDelegate
{
    if ([self.bannerCustomEvent respondsToSelector:@selector(invalidate)]) {
        // Secret API to allow us to detach the custom event from (shared instance) routers synchronously
        [self.bannerCustomEvent performSelector:@selector(invalidate)];
    }
    self.bannerCustomEvent.delegate = nil;

    // make sure the custom event isn't released synchronously as objects owned by the custom event
    // may do additional work after a callback that results in unregisterDelegate being called
    [[MPCoreInstanceProvider sharedProvider] keepObjectAliveForCurrentRunLoopIteration:_bannerCustomEvent];

    [super unregisterDelegate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting containerSize:(CGSize)size
{
    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);
    self.configuration = configuration;

    MPBannerCustomEvent *customEvent = [[configuration.customEventClass alloc] init];
    if (![customEvent isKindOfClass:[MPBannerCustomEvent class]]) {
        NSError * error = [NSError customEventClass:configuration.customEventClass doesNotInheritFrom:MPBannerCustomEvent.class];
        MPLogEvent([MPLogEvent error:error message:nil]);
        [self.delegate adapter:self didFailToLoadAdWithError:error];
        return;
    }


    self.bannerCustomEvent = customEvent;
    self.bannerCustomEvent.delegate = self;
    self.bannerCustomEvent.localExtras = targeting.localExtras;

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"adunit"] = configuration.adUnitId;
    if (CGSizeEqualToSize(size, CGSizeZero) == NO) {
        dict[@"whRatio"] = @(size.width/size.height);
    }
    dict[@"interval"] = @(configuration.refreshInterval);
    
    if ([self.delegate viewControllerForPresentingModalView] != nil) {
        dict[@"rootVC"] = [self.delegate viewControllerForPresentingModalView];
    } else {
        dict[@"rootVC"] = [self topVC];
    }
    
    [self.bannerCustomEvent requestAdWithSize:size customEventInfo:dict adMarkup:nil];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
    [self.bannerCustomEvent rotateToOrientation:newOrientation];
}

- (void)didDisplayAd
{
    if ([self.bannerCustomEvent enableAutomaticImpressionAndClickTracking]) {
        [self startViewableTrackingTimer];
    }

    [self.bannerCustomEvent didDisplayAd];
}

/// 获取顶层VC
- (UIViewController *)topVC {
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    if (![[UIApplication sharedApplication].windows containsObject:rootWindow]
        && [UIApplication sharedApplication].windows.count > 0) {
        rootWindow = [UIApplication sharedApplication].windows[0];
    }
    UIViewController *topVC = rootWindow.rootViewController;
    // 未读到keyWindow的rootViewController，则读UIApplicationDelegate的window，但该window不一定存在
    if (nil == topVC && [[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        topVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

#pragma mark - 1px impression tracking methods

- (void)startViewableTrackingTimer
{
    // Use defaults if server did not send values
    NSTimeInterval minimumSecondsForImpression = self.configuration.impressionMinVisibleTimeInSec >= 0 ? self.configuration.impressionMinVisibleTimeInSec : kDefaultRequiredSecondsInViewForImpression;
    CGFloat minimumPixelsForImpression = self.configuration.impressionMinVisiblePixels >= 0 ? self.configuration.impressionMinVisiblePixels : kDefaultRequiredPixelsInViewForImpression;

    self.impressionTimer = [[MPAdImpressionTimer alloc] initWithRequiredSecondsForImpression:minimumSecondsForImpression
                                                                requiredViewVisibilityPixels:minimumPixelsForImpression];
    self.impressionTimer.delegate = self;
    [self.impressionTimer startTrackingView:self.adView];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - MPPrivateBannerCustomEventDelegate

- (NSString *)adUnitId
{
    return [self.delegate banner].adUnitId;
}

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (id)bannerDelegate
{
    return [self.delegate bannerDelegate];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-implementations"
- (CLLocation *)location
{
    return [self.delegate location];
}
#pragma GCC diagnostic pop

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didLoadAd:(UIView *)ad
{
    [self didStopLoading];
    if (ad) {
        self.adView = ad;
        [self.delegate adapter:self didFinishLoadingAd:ad];
    } else {
        [self.delegate adapter:self didFailToLoadAdWithError:nil];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_Banner;
    model.so_t = [self.delegate sortType];
    model.posid = self.adUnitId;
    model.network = [self.delegate networkName];
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didFailToLoadAdWithError:(NSError *)error
{
    [self didStopLoading];
    [self.delegate adapter:self didFailToLoadAdWithError:error];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Banner;
    model.so_t = [self.delegate sortType];
    model.posid = self.adUnitId;
    model.network = [self.delegate networkName];
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

- (void)bannerCustomEventWillBeginAction:(MPBannerCustomEvent *)event
{
    [self trackClickOnce];
    [self.delegate userActionWillBeginForAdapter:self];
}

- (void)bannerCustomEventDidFinishAction:(MPBannerCustomEvent *)event
{
    [self.delegate userActionDidFinishForAdapter:self];
}

- (void)bannerCustomEventWillLeaveApplication:(MPBannerCustomEvent *)event
{
    [self trackClickOnce];
    [self.delegate userWillLeaveApplicationFromAdapter:self];
}

- (void)trackClickOnce
{
    if ([self.bannerCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedClick) {
        self.hasTrackedClick = YES;
        [self trackClick];
    }
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event willVisible:(UIView *)ad {
    
    [self.delegate adapter:self WillVisible:ad];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Show;
    model.st_t = AdLogAdType_Banner;
    model.so_t = [self.delegate sortType];
    model.posid = self.adUnitId;
    model.network = [self.delegate networkName];
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didClick:(UIView *)ad {
    [self.delegate adapter:self AdDidClick:ad];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Show;
    model.st_t = AdLogAdType_Banner;
    model.so_t = [self.delegate sortType];
    model.posid = self.adUnitId;
    model.network = [self.delegate networkName];
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event willClose:(UIView *)ad {
    [self.delegate adapter:self AdViewWillClose:ad];
}

- (void)bannerCustomEventWillExpandAd:(MPBannerCustomEvent *)event
{
    [self.delegate adWillExpandForAdapter:self];
}

- (void)bannerCustomEventDidCollapseAd:(MPBannerCustomEvent *)event
{
    [self.delegate adDidCollapseForAdapter:self];
}

- (void)trackImpression {
    [super trackImpression];

    // Notify delegate that an impression tracker was fired
    [self.delegate adapterDidTrackImpressionForAd:self];
}

#pragma mark - MPAdImpressionTimerDelegate

- (void)adViewWillLogImpression:(UIView *)adView
{
    // Track impression for all impression trackers known by the SDK
    [self trackImpression];
    // Track impression for all impression trackers included in the markup
    [self.bannerCustomEvent trackImpressionsIncludedInMarkup];
    // Start viewability tracking
    [self.bannerCustomEvent startViewabilityTracker];
}

@end
