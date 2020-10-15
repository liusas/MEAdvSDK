//
//  MobiFullscreenError.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import "MobiFullscreenError.h"

NSString * const MobiFullscreenVideoAdsSDKDomain = @"MobiFullscreenVideoAdsSDKDomain";
@implementation NSError (MobiFullscreenVideo)

+ (NSError *)fullscreenVideoErrorWithCode:(MobiFullscreenVideoErrorCode)code localizedDescription:(NSString *)description {
    NSDictionary * userInfo = nil;
    if (description != nil) {
        userInfo = @{ NSLocalizedDescriptionKey: description };
    }

    return [self errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:code userInfo:userInfo];
}

@end
