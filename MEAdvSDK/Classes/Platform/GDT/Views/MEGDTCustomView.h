//
//  MEGDTCustomView.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/1/8.
//

#import "GDTUnifiedNativeAdView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGDTCustomView : GDTUnifiedNativeAdView
@property (nonatomic, strong) UIView *backView;// 背景视图
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *clickButton;
@property (nonatomic, strong) UIButton *CTAButton;
@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UIImageView *midImageView;
@property (nonatomic, strong) UIImageView *rightImageView;

/// 图片广告的宽高比
@property (nonatomic, assign) CGFloat imageRate;

- (void)setupWithUnifiedNativeAdObject:(GDTUnifiedNativeAdDataObject *)unifiedNativeDataObject;

@end

NS_ASSUME_NONNULL_END
