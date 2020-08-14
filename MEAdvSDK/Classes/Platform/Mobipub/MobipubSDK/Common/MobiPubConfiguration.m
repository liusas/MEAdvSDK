//
//  MobiPubConfiguration.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/29.
//

#import "MobiPubConfiguration.h"

@implementation MobiPubConfiguration

- (instancetype)initWithAppIDForAppInitialization:(NSString *)appid {
    if (self = [super init]) {
        _appidForAppInitialization = appid;
        _loggingLevel = MobiLogLevelNone;
    }
    return self;
}

@end
