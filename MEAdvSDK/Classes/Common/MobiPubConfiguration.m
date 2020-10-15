//
//  MobiPubConfiguration.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/29.
//

#import "MobiPubConfiguration.h"

@implementation MobiPubConfiguration

- (instancetype)initWithAppIDForAppid:(NSString *)appid {
    if (self = [super init]) {
        _appid = appid;
        _loggingLevel = MPBLogLevelNone;
    }
    return self;
}

@end
