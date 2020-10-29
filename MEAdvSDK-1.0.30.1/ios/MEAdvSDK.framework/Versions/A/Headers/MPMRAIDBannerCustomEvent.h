//
//  MPMRAIDBannerCustomEvent.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPBannerCustomEvent.h"
#import "MPPrivateBannerCustomEventDelegate.h"

@interface MPMRAIDBannerCustomEvent : MPBannerCustomEvent

@property (nonatomic, weak) id<MPPrivateBannerCustomEventDelegate> delegate;

@end
