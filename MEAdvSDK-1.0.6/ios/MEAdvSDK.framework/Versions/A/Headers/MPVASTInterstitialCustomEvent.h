//
//  MPVASTInterstitialCustomEvent.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import "MPInterstitialCustomEvent.h"
#import "MPPrivateInterstitialCustomEventDelegate.h"
#import "MobiPrivateRewardedVideoCustomEventDelegate.h"
#import "MobiRewardedVideoCustomEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPVASTInterstitialCustomEvent: MPInterstitialCustomEvent

/**
 The actual delegate might only conform to one of the delegate protocol.
 */
@property (nonatomic, weak) id<MPPrivateInterstitialCustomEventDelegate, MobiPrivateRewardedVideoCustomEventDelegate> delegate;

@end

@interface MPVASTInterstitialCustomEvent (MobiRewardedVideoCustomEvent) <MobiRewardedVideoCustomEvent>
@end

NS_ASSUME_NONNULL_END
