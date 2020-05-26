//
//  MEGDTCustomView.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/1/8.
//

#import "MEGDTCustomView.h"

@implementation MEGDTCustomView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.backView];
        [self.backView addSubview:self.imageView];
        [self.backView addSubview:self.mediaView];
        [self.backView addSubview:self.iconImageView];
        [self.backView addSubview:self.titleLabel];
        [self.backView addSubview:self.descLabel];
        [self.backView addSubview:self.clickButton];
        [self.backView addSubview:self.leftImageView];
        [self.backView addSubview:self.midImageView];
        [self.backView addSubview:self.rightImageView];
        [self.backView addSubview:self.CTAButton];
    }
    return self;
}

- (void)setupWithUnifiedNativeAdObject:(GDTUnifiedNativeAdDataObject *)unifiedNativeDataObject
{
    self.titleLabel.text = unifiedNativeDataObject.title;
    self.descLabel.text = unifiedNativeDataObject.desc;
    NSURL *iconURL = [NSURL URLWithString:unifiedNativeDataObject.iconUrl];
    NSURL *imageURL = [NSURL URLWithString:unifiedNativeDataObject.imageUrl];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *iconData = [NSData dataWithContentsOfURL:iconURL];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.iconImageView.image = [UIImage imageWithData:iconData];
            self.imageView.image = [UIImage imageWithData:imageData];
        });
    });
    if ([unifiedNativeDataObject.callToAction length] > 0) {
        [self.clickButton setHidden:YES];
        [self.CTAButton setHidden:NO];
        [self.CTAButton setTitle:unifiedNativeDataObject.callToAction forState:UIControlStateNormal];
    } else {
        [self.clickButton setHidden:NO];
        [self.CTAButton setHidden:YES];
        
        if (unifiedNativeDataObject.isAppAd) {
            [self.clickButton setTitle:@"立即下载" forState:UIControlStateNormal];
        } else {
            [self.clickButton setTitle:@"立即打开" forState:UIControlStateNormal];
        }
    }
    
    
    if (unifiedNativeDataObject.isVideoAd) {
        self.mediaView.hidden = NO;
    } else {
        self.mediaView.hidden = YES;
    }
    
    if (unifiedNativeDataObject.isThreeImgsAd) {
        self.imageView.hidden = YES;
        self.leftImageView.hidden = NO;
        self.midImageView.hidden = NO;
        self.rightImageView.hidden = NO;
        NSURL *leftURL = [NSURL URLWithString:unifiedNativeDataObject.mediaUrlList[0]];
        NSURL *midURL = [NSURL URLWithString:unifiedNativeDataObject.mediaUrlList[1]];
        NSURL *rightURL = [NSURL URLWithString:unifiedNativeDataObject.mediaUrlList[2]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *leftData = [NSData dataWithContentsOfURL:leftURL];
            NSData *midData = [NSData dataWithContentsOfURL:midURL];
            NSData *rightData = [NSData dataWithContentsOfURL:rightURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.leftImageView.image = [UIImage imageWithData:leftData];
                self.midImageView.image = [UIImage imageWithData:midData];
                self.rightImageView.image = [UIImage imageWithData:rightData];
            });
        });
    } else {
        self.imageView.hidden = NO;
        self.leftImageView.hidden = YES;
        self.midImageView.hidden = YES;
        self.rightImageView.hidden = YES;
    }
}

#pragma mark - proerty getter
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
    }
    return _backView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
    }
    return _titleLabel;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor clearColor];
    }
    return _imageView;
}

- (UILabel *)descLabel
{
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
    }
    return _descLabel;
}

- (UIButton *)clickButton
{
    if (!_clickButton) {
        _clickButton = [[UIButton alloc] init];
    }
    return _clickButton;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
    }
    return _iconImageView;
}

- (UIImageView *)leftImageView
{
    if (!_leftImageView) {
        _leftImageView = [[UIImageView alloc] init];
    }
    return _leftImageView;
}

- (UIImageView *)midImageView
{
    if (!_midImageView) {
        _midImageView = [[UIImageView alloc] init];
    }
    return _midImageView;
}

- (UIImageView *)rightImageView
{
    if (!_rightImageView) {
        _rightImageView = [[UIImageView alloc] init];
    }
    return _rightImageView;
}

- (UIButton *)CTAButton {
    if (!_CTAButton) {
        _CTAButton = [[UIButton alloc] init];
    }
    
    return _CTAButton;
}

@end
