//
//  MPPrivateBannerCustomEventDelegate.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import "MPBannerCustomEventDelegate.h"

@class MobiConfig;

@protocol MPPrivateBannerCustomEventDelegate <MPBannerCustomEventDelegate>

- (NSString *)adUnitId;
- (MobiConfig *)configuration;
- (id)bannerDelegate;

@end
