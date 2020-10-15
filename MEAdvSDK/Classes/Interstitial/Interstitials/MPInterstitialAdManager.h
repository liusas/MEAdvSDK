//
//  MPInterstitialAdManager.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MobiAdConfigServer.h"
#import "MPBaseInterstitialAdapter.h"

@class MobiAdTargeting;
@protocol MPInterstitialAdManagerDelegate;

@interface MPInterstitialAdManager : NSObject <MobiAdConfigServerDelegate,
    MPInterstitialAdapterDelegate>

@property (nonatomic, weak) id<MPInterstitialAdManagerDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL ready;

- (id)initWithDelegate:(id<MPInterstitialAdManagerDelegate>)delegate;

- (void)loadInterstitialWithAdUnitID:(NSString *)ID targeting:(MobiAdTargeting *)targeting;
- (void)presentInterstitialFromViewController:(UIViewController *)controller;

@end
