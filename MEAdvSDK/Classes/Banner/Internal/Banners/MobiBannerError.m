//
//  MobiBannerError.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import "MobiBannerError.h"

NSString * const MobiBannerAdsSDKDomain = @"MobiBannerAdsSDKDomain";

@implementation NSError (MobiBanner)

+ (NSError *)feedErrorWithCode:(MobiBannerErrorCode)code localizedDescription:(NSString *)description {
    
    NSDictionary * userInfo = nil;
    if (description != nil) {
        userInfo = @{ NSLocalizedDescriptionKey: description };
    }

    return [self errorWithDomain:MobiBannerAdsSDKDomain code:code userInfo:userInfo];
}

@end
