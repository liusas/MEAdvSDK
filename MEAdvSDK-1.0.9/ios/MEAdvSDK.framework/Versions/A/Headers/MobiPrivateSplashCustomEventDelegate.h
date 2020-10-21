//
//  MobiPrivateSplashCustomEventDelegate.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import "MobiSplashCustomEvent.h"

@class MobiConfig;
@protocol MobiPrivateSplashCustomEventDelegate<MobiSplashCustomEventDelegate>

- (NSString *)adUnitId;
- (MobiConfig *)configuration;

@end
