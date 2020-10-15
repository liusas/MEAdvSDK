//
//  MobiSplashError.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import "MobiSplashError.h"

NSString * const MobiSplashAdsSDKDomain = @"MobiSplashAdsSDKDomain";

@implementation NSError (MobiSplash)

+ (NSError *)splashErrorWithCode:(MobiSplashErrorCode)code localizedDescription:(NSString *)description {
    NSDictionary * userInfo = nil;
    if (description != nil) {
        userInfo = @{ NSLocalizedDescriptionKey: description };
    }

    return [self errorWithDomain:MobiSplashAdsSDKDomain code:code userInfo:userInfo];
}

@end
