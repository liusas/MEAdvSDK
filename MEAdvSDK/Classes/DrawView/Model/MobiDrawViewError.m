//
//  MobiDrawViewError.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import "MobiDrawViewError.h"

NSString * const MobiDrawViewAdsSDKDomain = @"MobiDrawViewAdsSDKDomain";

@implementation NSError (MobiDrawView)


+ (NSError *)drawViewErrorWithCode:(MobiDrawViewErrorCode)code localizedDescription:(NSString *)description {
    NSDictionary * userInfo = nil;
    if (description != nil) {
        userInfo = @{ NSLocalizedDescriptionKey: description };
    }

    return [self errorWithDomain:MobiDrawViewAdsSDKDomain code:code userInfo:userInfo];
}

@end
