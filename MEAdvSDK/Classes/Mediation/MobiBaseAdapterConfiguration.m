//
//  MobiBaseAdapterConfiguration.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MobiBaseAdapterConfiguration.h"
#import "MEAdNetworkManager.h"

@interface MobiBaseAdapterConfiguration()
@property (nonatomic, readonly) NSMutableDictionary<NSString *, NSString *> * internalmobiPubRequestOptions;
@end

@implementation MobiBaseAdapterConfiguration
@dynamic adapterVersion;
@dynamic biddingToken;
@dynamic mobiNetworkName;
@dynamic networkSdkVersion;

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        _internalmobiPubRequestOptions = [NSMutableDictionary dictionary];
    }

    return self;
}

#pragma mark - MobiAdapterConfiguration Default Implementations

- (NSDictionary<NSString *, NSString *> *)mobiPubRequestOptions {
    return self.internalmobiPubRequestOptions;
}

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> * _Nullable)configuration
                                  complete:(void(^ _Nullable)(NSError * _Nullable))complete {
    if (complete != nil) {
        complete(nil);
    }
}

- (void)addMobiPubRequestOptions:(NSDictionary<NSString *, NSString *> *)options {
    // No entries to add
    if (options == nil) {
        return;
    }

    [self.internalmobiPubRequestOptions addEntriesFromDictionary:options];
}

+ (void)setCachedInitializationParameters:(NSDictionary * _Nullable)params {
//    [MPMediationManager.sharedManager setCachedInitializationParameters:params forNetwork:self.class];
}

+ (NSDictionary * _Nullable)cachedInitializationParameters {
//    return [MPMediationManager.sharedManager cachedInitializationParametersForNetwork:self.class];
    return nil;
}

@end
