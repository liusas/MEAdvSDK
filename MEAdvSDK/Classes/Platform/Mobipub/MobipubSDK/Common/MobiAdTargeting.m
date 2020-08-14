//
//  MobiAdTargeting.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import "MobiAdTargeting.h"

@implementation MobiAdTargeting

- (instancetype)initWithCreativeSafeSize:(CGSize)size {
    if (self = [super init]) {
        self.creativeSafeSize = size;
    }

    return self;
}

+ (instancetype)targetingWithCreativeSafeSize:(CGSize)size {
    return [[MobiAdTargeting alloc] initWithCreativeSafeSize:size];
}

@end
