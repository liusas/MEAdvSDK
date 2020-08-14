//
//  MPBaseInterstitialAdapter.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPBaseInterstitialAdapter.h"
#import "MobiConfig.h"
#import "MobiGlobal.h"
#import "MobiAnalyticsTracker.h"
#import "MPCoreInstanceProvider.h"
#import "MPError.h"
#import "MobiTimer.h"
#import "MPConstants.h"

@interface MPBaseInterstitialAdapter ()

@property (nonatomic, strong) MobiConfig *configuration;
@property (nonatomic, strong) MobiTimer *timeoutTimer;

- (void)startTimeoutTimer;

@end

@implementation MPBaseInterstitialAdapter

- (id)initWithDelegate:(id<MPInterstitialAdapterDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [self unregisterDelegate];

    [self.timeoutTimer invalidate];

}

- (void)unregisterDelegate
{
    self.delegate = nil;
}

- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting
{
    // To be implemented by subclasses.
    [self doesNotRecognizeSelector:_cmd];
}

- (void)_getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting
{
    self.configuration = configuration;

    [self startTimeoutTimer];
    [self getAdWithConfiguration:configuration targeting:targeting];
}

- (void)startTimeoutTimer
{
    NSTimeInterval timeInterval = (self.configuration && self.configuration.adTimeoutInterval >= 0) ?
            self.configuration.adTimeoutInterval : INTERSTITIAL_TIMEOUT_INTERVAL;

    if (timeInterval > 0) {
        self.timeoutTimer = [MobiTimer timerWithTimeInterval:timeInterval
                                                    target:self
                                                  selector:@selector(timeout)
                                                   repeats:NO];
        [self.timeoutTimer scheduleNow];
    }
}

- (void)didStopLoading
{
    [self.timeoutTimer invalidate];
}

- (void)timeout
{
    NSError * error = [NSError errorWithCode:MOPUBErrorAdRequestTimedOut localizedDescription:@"Interstitial ad request timed out"];
    [self.delegate adapter:self didFailToLoadAdWithError:error];
    self.delegate = nil;
}

#pragma mark - Presentation

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Metrics

- (void)trackImpression
{
    [[MobiAnalyticsTracker sharedTracker] trackImpressionForConfiguration:self.configuration];
    [self.delegate interstitialDidReceiveImpressionEventForAdapter:self];
}

- (void)trackClick
{
    [[MobiAnalyticsTracker sharedTracker] trackClickForConfiguration:self.configuration];
}

@end

