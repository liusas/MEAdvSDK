//
//  MPPrivateInterstitialCustomEventDelegate.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import "MPInterstitialCustomEventDelegate.h"

@class MobiConfig;
@class CLLocation;

@protocol MPPrivateInterstitialCustomEventDelegate <MPInterstitialCustomEventDelegate>

- (NSString *)adUnitId;
- (MobiConfig *)configuration;
- (id)interstitialDelegate;

@end
