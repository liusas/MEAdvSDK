//
//  MobiPrivateFeedCustomEventDelegate.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import "MobiFeedCustomEvent.h"

@class MobiConfig;

@protocol MobiPrivateFeedCustomEventDelegate <MobiFeedCustomEventDelegate>

- (NSString *)adUnitId;
- (MobiConfig *)configuration;

@end
