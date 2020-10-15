//
//  MobiRewardedVideoError.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import "MobiRewardedVideoError.h"

NSString * const MobiRewardedVideoAdsSDKDomain = @"MobiRewardedVideoAdsSDKDomain";
@implementation NSError (MobiRewardVideo)

+ (NSError *)splashErrorWithCode:(MobiRewardedVideoErrorCode)code localizedDescription:(NSString *)description {
    NSDictionary * userInfo = nil;
    if (description != nil) {
        userInfo = @{ NSLocalizedDescriptionKey: description };
    }

    return [self errorWithDomain:MobiRewardedVideoAdsSDKDomain code:code userInfo:userInfo];
}

@end
