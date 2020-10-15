//
//  MPMRAIDInterstitialViewController.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPInterstitialViewController.h"
#import "MPForceableOrientationProtocol.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

@class MobiConfig;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPMRAIDInterstitialViewController : MPInterstitialViewController <MPForceableOrientationProtocol>

- (id)initWithAdConfiguration:(MobiConfig *)configuration;
- (void)startLoading;

@end

