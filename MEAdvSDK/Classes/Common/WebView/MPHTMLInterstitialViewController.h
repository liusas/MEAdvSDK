//
//  MPHTMLInterstitialViewController.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <UIKit/UIKit.h>

#import "MPAdWebViewAgent.h"
#import "MPInterstitialViewController.h"

@class MobiConfig;

@interface MPHTMLInterstitialViewController : MPInterstitialViewController <MPAdWebViewAgentDelegate>

@property (nonatomic, strong) MPAdWebViewAgent *backingViewAgent;

- (void)loadConfiguration:(MobiConfig *)configuration;

@end
