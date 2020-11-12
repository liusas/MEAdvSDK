//
//  MPInterstitialCustomEventAdapter.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPInterstitialCustomEventAdapter.h"

#import "MobiConfig.h"
#import "MobiAdTargeting.h"
#import "MPConstants.h"
#import "MPCoreInstanceProvider.h"
#import "MPError.h"
#import "MPHTMLInterstitialCustomEvent.h"
#import "MPLogging.h"
#import "MPInterstitialCustomEvent.h"
#import "MPInterstitialAdController.h"
#import "MPMRAIDInterstitialCustomEvent.h"
#import "MPVASTInterstitialCustomEvent.h"
#import "MobiRealTimeTimer.h"

#import "MELogTracker.h"

@interface MPInterstitialCustomEventAdapter ()

@property (nonatomic, strong) MPInterstitialCustomEvent *interstitialCustomEvent;
@property (nonatomic, strong) MobiConfig *configuration;
@property (nonatomic, assign) BOOL hasTrackedImpression;
@property (nonatomic, assign) BOOL hasTrackedClick;
@property (nonatomic, strong) MobiRealTimeTimer *expirationTimer;

@end

@implementation MPInterstitialCustomEventAdapter

- (void)dealloc
{
    if ([self.interstitialCustomEvent respondsToSelector:@selector(invalidate)]) {
        // Secret API to allow us to detach the custom event from (shared instance) routers synchronously
        // See the chartboost interstitial custom event for an example use case.
        [self.interstitialCustomEvent performSelector:@selector(invalidate)];
    }
    self.interstitialCustomEvent.delegate = nil;

    // make sure the custom event isn't released synchronously as objects owned by the custom event
    // may do additional work after a callback that results in dealloc being called
    [[MPCoreInstanceProvider sharedProvider] keepObjectAliveForCurrentRunLoopIteration:_interstitialCustomEvent];
}

- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting
{
    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);
    self.configuration = configuration;

    MPInterstitialCustomEvent *customEvent = [[configuration.customEventClass alloc] init];
    if (![customEvent isKindOfClass:[MPInterstitialCustomEvent class]]) {
        NSError * error = [NSError customEventClass:configuration.customEventClass doesNotInheritFrom:MPInterstitialCustomEvent.class];
        MPLogEvent([MPLogEvent error:error message:nil]);
        [self.delegate adapter:self didFailToLoadAdWithError:error];
        return;
    }
    customEvent.delegate = self;
    customEvent.localExtras = targeting.localExtras;
    self.interstitialCustomEvent = customEvent;

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"width"] = @(300);
    dict[@"height"] = @(300);
    dict[@"adunit"] = configuration.adUnitId;
    
    [self.interstitialCustomEvent requestInterstitialWithCustomEventInfo:dict adMarkup:nil];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [self.interstitialCustomEvent showInterstitialFromRootViewController:controller];
}

#pragma mark - MPInterstitialCustomEventDelegate

- (NSString *)adUnitId
{
    return [self.delegate interstitialAdController].adUnitId;
}

- (CLLocation *)location
{
    return [self.delegate location];
}

- (id)interstitialDelegate
{
    return [self.delegate interstitialDelegate];
}

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
                      didLoadAd:(id)ad
{
    [self didStopLoading];
    [self.delegate adapterDidFinishLoadingAd:self];

    // Check for MoPub-specific custom events before setting the timer
    // Custom events for 3rd party SDK have their own timeout and expiration handling
    if ([customEvent isKindOfClass:[MPHTMLInterstitialCustomEvent class]]
        || [customEvent isKindOfClass:[MPMRAIDInterstitialCustomEvent class]]
        || [customEvent isKindOfClass:[MPVASTInterstitialCustomEvent class]]) {
        // Set up timer for expiration
        __weak __typeof__(self) weakSelf = self;
        self.expirationTimer = [[MobiRealTimeTimer alloc] initWithInterval:[MPConstants adsExpirationInterval] block:^(MobiRealTimeTimer *timer){
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (strongSelf && !strongSelf.hasTrackedImpression) {
                [strongSelf interstitialCustomEventDidExpire:strongSelf.interstitialCustomEvent];
            }
            [strongSelf.expirationTimer invalidate];
        }];
        [self.expirationTimer scheduleNow];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_Interstitial;
     model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
     
     
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
       didFailToLoadAdWithError:(NSError *)error
{
    [self didStopLoading];
    [self.delegate adapter:self didFailToLoadAdWithError:error];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Interstitial;
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
//     
//     
//    // 立即上传
//    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)interstitialCustomEventWillAppear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialWillAppearForAdapter:self];
}

- (void)interstitialCustomEventDidAppear:(MPInterstitialCustomEvent *)customEvent
{
    if ([self.interstitialCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedImpression) {
        [self trackImpression];
    }
    [self.delegate interstitialDidAppearForAdapter:self];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Show;
    model.st_t = AdLogAdType_Interstitial;
     model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
     
     
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)interstitialCustomEventWillDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialWillDisappearForAdapter:self];
}

- (void)interstitialCustomEventDidDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialDidDisappearForAdapter:self];
}

- (void)interstitialCustomEventWillPresentModal:(MPInterstitialCustomEvent *)customEvent {
    [self.delegate interstitialWillPresentModalForAdapter:self];
}

- (void)interstitialCustomEventDidDismissModal:(MPInterstitialCustomEvent *)customEvent {
    [self.delegate interstitialDidDismissModalForAdapter:self];
}

- (void)interstitialCustomEventDidExpire:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialDidExpireForAdapter:self];
}

- (void)interstitialCustomEventDidReceiveTapEvent:(MPInterstitialCustomEvent *)customEvent
{
    if ([self.interstitialCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedClick) {
        self.hasTrackedClick = YES;
        [self trackClick];
    }

    [self.delegate interstitialDidReceiveTapEventForAdapter:self];
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_Interstitial;
     model.so_t = self.configuration.sortType;
    model.posid = self.configuration.adUnitId;
    model.network = self.configuration.networkName;
    model.nt_name = self.configuration.ntName;
    model.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
     
     
    // 立即上传
    [MELogTracker uploadImmediatelyWithLogModels:@[model]];
}

- (void)interstitialCustomEventWillLeaveApplication:(MPInterstitialCustomEvent *)customEvent
{
    [self.delegate interstitialWillLeaveApplicationForAdapter:self];
}

- (void)trackImpression {
    [super trackImpression];
    self.hasTrackedImpression = YES;
    [self.expirationTimer invalidate];
}

@end
