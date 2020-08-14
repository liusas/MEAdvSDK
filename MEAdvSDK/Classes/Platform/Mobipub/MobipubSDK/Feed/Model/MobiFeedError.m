//
//  MobiFeedError.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import "MobiFeedError.h"

NSString * const MobiFeedAdsSDKDomain = @"MobiFeedAdsSDKDomain";

@implementation NSError (MobiFeed)

+ (NSError *)feedErrorWithCode:(MobiFeedErrorCode)code localizedDescription:(NSString *)description {
    
    NSDictionary * userInfo = nil;
    if (description != nil) {
        userInfo = @{ NSLocalizedDescriptionKey: description };
    }

    return [self errorWithDomain:MobiFeedAdsSDKDomain code:code userInfo:userInfo];
}

@end
