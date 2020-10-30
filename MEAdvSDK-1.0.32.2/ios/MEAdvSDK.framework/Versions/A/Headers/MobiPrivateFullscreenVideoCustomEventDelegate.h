//
//  MobiPrivateRewardedVideoCustomEventDelegate.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import "MobiFullscreenCustomEvent.h"

@class MobiConfig;

@protocol MobiPrivateFullscreenVideoCustomEventDelegate <MobiFullscreenVideoCustomEventDelegate>

- (NSString *)adUnitId;
- (MobiConfig *)configuration;

@end
