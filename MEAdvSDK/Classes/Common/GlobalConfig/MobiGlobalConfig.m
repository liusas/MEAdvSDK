//
//  MobiGlobalConfig.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/23.
//

#import "MobiGlobalConfig.h"

@implementation MobiGlobalConfig

+ (instancetype)sharedInstance {
    static MobiGlobalConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MobiGlobalConfig alloc] init];
    });
    return sharedInstance;
}

@end
