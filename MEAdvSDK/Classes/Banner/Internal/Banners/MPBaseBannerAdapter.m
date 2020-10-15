//
//  MPBaseBannerAdapter.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPBaseBannerAdapter.h"
#import "MPConstants.h"

#import "MobiConfig.h"
#import "MPLogging.h"
#import "MPCoreInstanceProvider.h"
#import "MobiAnalyticsTracker.h"
#import "MobiTimer.h"
#import "MPError.h"

@interface MPBaseBannerAdapter ()

@property (nonatomic, strong) MobiConfig *configuration;
@property (nonatomic, strong) MobiTimer *timeoutTimer;
@property (nonatomic, strong) id<MobiAnalyticsTracker> analyticsTracker;

- (void)startTimeoutTimer;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPBaseBannerAdapter

- (instancetype)initWithDelegate:(id<MPBannerAdapterDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
        self.analyticsTracker = [MobiAnalyticsTracker sharedTracker];
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

#pragma mark - Requesting Ads

- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting containerSize:(CGSize)size
{
    // To be implemented by subclasses.
    [self doesNotRecognizeSelector:_cmd];
}

- (void)_getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting containerSize:(CGSize)size
{
    self.configuration = configuration;

//    [self startTimeoutTimer];
    [self getAdWithConfiguration:configuration targeting:targeting containerSize:size];
}

- (void)didStopLoading
{
    [self.timeoutTimer invalidate];
}

- (void)didDisplayAd
{
    [self trackImpression];
}

- (void)startTimeoutTimer
{
    NSTimeInterval timeInterval = (self.configuration && self.configuration.adTimeoutInterval >= 0) ?
    self.configuration.adTimeoutInterval : BANNER_TIMEOUT_INTERVAL;

    if (timeInterval > 0) {
        self.timeoutTimer = [MobiTimer timerWithTimeInterval:timeInterval
                                                    target:self
                                                  selector:@selector(timeout)
                                                   repeats:NO];
        [self.timeoutTimer scheduleNow];
    }
}

- (void)timeout
{
    NSError * error = [NSError errorWithCode:MOPUBErrorAdRequestTimedOut
                           localizedDescription:@"Banner ad request timed out"];
    [self.delegate adapter:self didFailToLoadAdWithError:error];
}

#pragma mark - Rotation

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
    // Do nothing by default. Subclasses can override.
}

#pragma mark - Metrics

- (void)trackImpression
{
    [self.analyticsTracker trackImpressionForConfiguration:self.configuration];
}

- (void)trackClick
{
    [self.analyticsTracker trackClickForConfiguration:self.configuration];
}

@end
