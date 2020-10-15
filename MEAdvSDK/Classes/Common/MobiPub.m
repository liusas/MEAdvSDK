//
//  MobiPub.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/28.
//

#import "MobiPub.h"
#import "MPConstants.h"
#import "MobiExperimentProvider.h"
#import "MobiGlobalConfigServer.h"
#import "MPLogging.h"

@interface MobiPub ()

@property (nonatomic, strong) NSArray *globalMediationSettings;

@property (nonatomic, assign, readwrite) BOOL isSdkInitialized;

@property (nonatomic, strong) MobiExperimentProvider *experimentProvider;

@property (nonatomic, strong) MobiGlobalConfigServer *configServer;

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
        _configServer = [[MobiGlobalConfigServer alloc] init];
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
        MPLogging.consoleLogLevel = configuration.loggingLevel;
        
        [self.configServer loadWithConfiguration:configuration finished:^(NSDictionary * _Nonnull serverConfig) {
            self.isSdkInitialized = YES;
            
//            MPLogEvent([MPLogEvent sdkInitializedWithNetworks:initializedNetworks]);
            if (completionBlock) {
                completionBlock();
            }
        }];
    }
}

@end
