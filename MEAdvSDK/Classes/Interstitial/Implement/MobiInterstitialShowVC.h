//
//  MobiInterstitialShowVC.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/8/11.
//

#import "MPInterstitialViewController.h"
@class MobiConfig;
NS_ASSUME_NONNULL_BEGIN

@interface MobiInterstitialShowVC : MPInterstitialViewController

@property (nonatomic, strong) MobiConfig *configuration;
@property (nonatomic, copy) NSString *imgUrl;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@end

NS_ASSUME_NONNULL_END
