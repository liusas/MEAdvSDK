//
//  MobiRewardedVideoReward.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import "MobiRewardedVideoReward.h"

NSString *const kMobiRewardedVideoRewardCurrencyTypeUnspecified = @"MPMoPubRewardedVideoRewardCurrencyTypeUnspecified";
NSInteger const kMobiRewardedVideoRewardCurrencyAmountUnspecified = 0;

@implementation MobiRewardedVideoReward

- (instancetype)initWithCurrencyType:(NSString *)currencyType amount:(NSNumber *)amount
{
    if (self = [super init]) {
        _currencyType = currencyType;
        _amount = amount;
    }

    return self;
}

- (instancetype)initWithCurrencyAmount:(NSNumber *)amount
{
    return [self initWithCurrencyType:kMobiRewardedVideoRewardCurrencyTypeUnspecified amount:amount];
}

- (NSString *)description {
    NSString * message = nil;
    if (self.amount != nil && self.currencyType != nil) {
        message = [NSString stringWithFormat:@"%@ %@", self.amount, self.currencyType];
    }
    return message;
}

@end
