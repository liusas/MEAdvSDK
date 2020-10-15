//
//  MobiExperimentProvider.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/28.
//

#import "MobiExperimentProvider.h"

@interface MobiExperimentProvider ()

@property (nonatomic, assign) BOOL isDisplayAgentOverriddenByClient;

@end

@implementation MobiExperimentProvider

@synthesize displayAgentType = _displayAgentType;

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _isDisplayAgentOverriddenByClient = NO;
        _displayAgentType = MobiPubDisplayAgentTypeInApp;
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id _sharedInstance;
    dispatch_once(&once, ^{
        _sharedInstance = [self new];
    });
    return _sharedInstance;
}

- (void)setDisplayAgentType:(MobiPubDisplayAgentType)displayAgentType {
    _isDisplayAgentOverriddenByClient = YES;
    _displayAgentType = displayAgentType;
}

- (void)setDisplayAgentFromAdServer:(MobiPubDisplayAgentType)displayAgentType {
    if (!self.isDisplayAgentOverriddenByClient) {
        _displayAgentType = displayAgentType;
    }
}

@end
