//
//  MobiPrivateRewardedVideoCustomEventDelegate.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import "MobiRewardedVideoCustomEvent.h"

@class MobiConfig;

@protocol MobiPrivateRewardedVideoCustomEventDelegate <MobiRewardedVideoCustomEventDelegate>

- (NSString *)adUnitId;
- (MobiConfig *)configuration;

@end
