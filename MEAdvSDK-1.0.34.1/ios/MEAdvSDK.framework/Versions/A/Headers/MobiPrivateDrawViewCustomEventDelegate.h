//
//  MobiPrivateDrawViewCustomEventDelegate.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import "MobiDrawViewCustomEvent.h"

@class MobiConfig;

@protocol MobiPrivateDrawViewCustomEventDelegate <MobiDrawViewCustomEventDelegate>

- (NSString *)adUnitId;
- (MobiConfig *)configuration;

@end
