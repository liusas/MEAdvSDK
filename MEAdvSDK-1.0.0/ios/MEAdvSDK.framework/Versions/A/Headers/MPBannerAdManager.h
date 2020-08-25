//
//  MPBannerAdManager.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import "MobiAdConfigServer.h"
#import "MPBaseBannerAdapter.h"

@class MobiAdTargeting;

@protocol MPBannerAdManagerDelegate;

@interface MPBannerAdManager : NSObject <MobiAdConfigServerDelegate, MPBannerAdapterDelegate>

@property (nonatomic, weak) id<MPBannerAdManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isMraidAd;

- (id)initWithDelegate:(id<MPBannerAdManagerDelegate>)delegate;

- (void)loadAdWithTargeting:(MobiAdTargeting *)targeting;
- (void)forceRefreshAd;
- (void)stopAutomaticallyRefreshingContents;
- (void)startAutomaticallyRefreshingContents;
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation;

@end
