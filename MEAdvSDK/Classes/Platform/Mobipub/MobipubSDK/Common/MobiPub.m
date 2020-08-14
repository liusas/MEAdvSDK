//
//  MobiPub.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/28.
//

#import "MobiPub.h"
#import "MPConstants.h"
#import "MobiExperimentProvider.h"


@interface MobiPub ()

@property (nonatomic, strong) NSArray *globalMediationSettings;

@property (nonatomic, assign, readwrite) BOOL isSdkInitialized;

@property (nonatomic, strong) MobiExperimentProvider *experimentProvider;

@end

@implementation MobiPub

+ (MobiPub *)sharedInstance
{
    static MobiPub *sharedInstance = nil;
    static dispatch_once_t initOnceToken;
    dispatch_once(&initOnceToken, ^{
        sharedInstance = [[MobiPub alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInitWithExperimentProvider:MobiExperimentProvider.sharedInstance];
    }
    return self;
}

/**
 This common init enables unit testing with an `MobiPubExperimentProvider` instance that is not a singleton.
 */
- (void)commonInitWithExperimentProvider:(MobiExperimentProvider *)experimentProvider {
    _experimentProvider = experimentProvider;
}

//- (void)setLocationUpdatesEnabled:(BOOL)locationUpdatesEnabled
//{
////    [MPGeolocationProvider.sharedProvider setLocationUpdatesEnabled:locationUpdatesEnabled];
//}
//
//- (BOOL)locationUpdatesEnabled
//{
////    return MPGeolocationProvider.sharedProvider.locationUpdatesEnabled;
//}

- (void)setFrequencyCappingIdUsageEnabled:(BOOL)frequencyCappingIdUsageEnabled
{
//    [MPIdentityProvider setFrequencyCappingIdUsageEnabled:frequencyCappingIdUsageEnabled];
}

//- (void)setClickthroughDisplayAgentType:(MOPUBDisplayAgentType)displayAgentType
//{
//    self.experimentProvider.displayAgentType = displayAgentType;
//}

- (BOOL)frequencyCappingIdUsageEnabled
{
//    return [MPIdentityProvider frequencyCappingIdUsageEnabled];
    return YES;
}

// Keep -version and -bundleIdentifier methods around for Fabric backwards compatibility.
- (NSString *)version
{
    return MP_SDK_VERSION;
}

- (NSString *)bundleIdentifier
{
    return MP_BUNDLE_IDENTIFIER;
}

- (void)initializeSdkWithConfiguration:(MobiPubConfiguration *)configuration
                            completion:(void(^_Nullable)(void))completionBlock
{
    if (@available(iOS 9, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self setSdkWithConfiguration:configuration completion:completionBlock];
        });
    } else {
//        MPLogEvent([MPLogEvent error:[NSError sdkMinimumOsVersion:9] message:nil]);
        NSAssert(false, @"MoPub SDK requires iOS 9 and up");
    }
}

- (void)setSdkWithConfiguration:(MobiPubConfiguration *)configuration
                     completion:(void(^_Nullable)(void))completionBlock
{
    @synchronized (self) {
        self.isSdkInitialized = YES;
#if 0
        // Set the console logging level.
//        MPLogging.consoleLogLevel = configuration.loggingLevel;

        // Store the global mediation settings
//        self.globalMediationSettings = configuration.globalMediationSettings;

        // Create a dispatch group to synchronize mutliple asynchronous tasks.
        dispatch_group_t initializationGroup = dispatch_group_create();

        // Configure the consent manager and synchronize regardless of the result
        // of `checkForDoNotTrackAndTransition`.
        dispatch_group_enter(initializationGroup);
        // If the publisher has changed their adunit ID for app initialization, clear our adunit ID caches
        NSString * cachedPublisherEnteredAdUnitID = [NSUserDefaults.standardUserDefaults stringForKey:kPublisherEnteredAdUnitIdStorageKey];
        if (![configuration.adUnitIdForAppInitialization isEqualToString:cachedPublisherEnteredAdUnitID]) {
            [MPConsentManager.sharedManager clearAdUnitIdUsedForConsent];
            [NSUserDefaults.standardUserDefaults setObject:configuration.adUnitIdForAppInitialization forKey:kPublisherEnteredAdUnitIdStorageKey];
        }
        MPConsentManager.sharedManager.adUnitIdUsedForConsent = configuration.adUnitIdForAppInitialization;
        MPConsentManager.sharedManager.allowLegitimateInterest = configuration.allowLegitimateInterest;
        [MPConsentManager.sharedManager checkForDoNotTrackAndTransition];
        [MPConsentManager.sharedManager synchronizeConsentWithCompletion:^(NSError * _Nullable error) {
            dispatch_group_leave(initializationGroup);
        }];

        // Configure session tracker
        [MPSessionTracker initializeNotificationObservers];

        // Configure mediated network SDKs
        __block NSArray<id<MPAdapterConfiguration>> * initializedNetworks = nil;
        dispatch_group_enter(initializationGroup);
        [MPMediationManager.sharedManager initializeWithAdditionalProviders:configuration.additionalNetworks
                                                             configurations:configuration.mediatedNetworkConfigurations
                                                             requestOptions:configuration.moPubRequestOptions
                                                                   complete:^(NSError * error, NSArray<id<MPAdapterConfiguration>> * initializedAdapters) {
            initializedNetworks = initializedAdapters;
            dispatch_group_leave(initializationGroup);
        }];

        // Once all of the asynchronous tasks have completed, notify the
        // completion handler.
        dispatch_group_notify(initializationGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            MPLogEvent([MPLogEvent sdkInitializedWithNetworks:initializedNetworks]);
            self.isSdkInitialized = YES;
            if (completionBlock) {
                completionBlock();
            }
        });
#endif
    }
}

@end
