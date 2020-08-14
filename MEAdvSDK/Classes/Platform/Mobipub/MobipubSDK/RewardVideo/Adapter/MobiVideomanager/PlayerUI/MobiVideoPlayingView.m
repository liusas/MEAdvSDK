//
//  VideoPlayingView.m
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/30.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import "MobiVideoPlayingView.h"
#import "MobiVideoAppConfig.h"
#import "UIView+MobiFrame.h"
#import "UIColor+MobiBaseFramework.h"
#import <AVFoundation/AVFoundation.h>
#import "MobiGlobal.h"


@interface MobiVideoPlayingView ()
/// 倒计时按钮
@property (nonatomic, strong) MobiVideoAdButton *jumpBtn;
/// logo
@property (nonatomic, strong) MobiLaunchAdImageView *logoImageV;
/// logo2
@property (nonatomic, strong) MobiLaunchAdImageView *bottomImgV;
/// app name
@property (nonatomic, strong) UILabel *appNameLb;
/// app describe
@property (nonatomic, strong) UILabel *appDescribeLb;
/// download Btn
@property (nonatomic, strong) UIButton *downloadBtn;
@end

@implementation MobiVideoPlayingView

- (instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        [self createUI];
    }
    return self;
}

- (void)createUI{
    
    //logo
    MobiLaunchAdImageView *logo = [[MobiLaunchAdImageView alloc] init];
    logo.frame = CGRectMake(kCurrentWidth(16), kCurrentWidth(5)+iPhoneStatusBarAndNavigationBarHeight, kCurrentWidth(62), kCurrentWidth(62));
    logo.layer.cornerRadius = kCurrentWidth(7);
    logo.clipsToBounds = YES;
    [self addSubview:logo];
    logo.hidden = YES;
    self.logoImageV = logo;
    
    //jump button
    MobiVideoAdButton *jumpBtn = [[MobiVideoAdButton alloc] init];
    //MobiVideoAdButton *jumpBtn = [[MobiVideoAdButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - kCurrentWidth(48), kCurrentWidth(5)+iPhoneStatusBarAndNavigationBarHeight, kCurrentWidth(31), kCurrentWidth(31))];
    //[jumpBtn setTitleWithSkipType:MobiSkipTypeRoundProgressTime duration:10];
//    [jumpBtn setTitle:@"5" forState:UIControlStateNormal];
//    jumpBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.56];
//    jumpBtn.layer.cornerRadius = kCurrentWidth(31/2);
//    jumpBtn.clipsToBounds = YES;
    [self addSubview:jumpBtn];
    self.jumpBtn = jumpBtn;
    [jumpBtn addTarget:self action:@selector(jumpClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //speaker button
    UIButton *speakerBtn = [[UIButton alloc] initWithFrame:CGRectMake(kCurrentWidth(287), CGRectGetMinY(jumpBtn.frame), kCurrentWidth(31), kCurrentWidth(31))];
    
    [speakerBtn setImage:[UIImage imageNamed:MPResourcePathForResource(@"喇叭")] forState:UIControlStateNormal];
    speakerBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.34];
    speakerBtn.layer.cornerRadius = kCurrentWidth(31/2);
    speakerBtn.clipsToBounds = YES;
    [self addSubview:speakerBtn];
    [speakerBtn addTarget:self action:@selector(speakClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *backV = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - kCurrentWidth(122), kCurrentWidth(343), kCurrentWidth(102))];
    backV.centerX = self.centerX;
    backV.backgroundColor = [UIColor whiteColor];
    backV.layer.cornerRadius = kCurrentWidth(19);
    backV.clipsToBounds = YES;
    [self addSubview:backV];
    
    //bottom logo
    MobiLaunchAdImageView *logo2 = [[MobiLaunchAdImageView alloc] init];
    logo2.layer.cornerRadius = kCurrentWidth(7);
    logo2.clipsToBounds = YES;
    logo2.frame = CGRectMake(kCurrentWidth(16), kCurrentWidth(20), kCurrentWidth(62), kCurrentWidth(62));
    [backV addSubview:logo2];
    self.bottomImgV = logo2;
    
    //app name
    UILabel *nameLb = [[UILabel alloc] initWithFrame:CGRectMake(kCurrentWidth(13) + logo2.maxX, kCurrentWidth(27), kCurrentWidth(100), kCurrentWidth(25))];
    nameLb.text = @"小黄儿";
    nameLb.textColor = [UIColor colorWithHexString:@"333333"];
    nameLb.font = [UIFont fontWithName:MediumFontName size:kCurrentWidth(18)];
    [backV addSubview:nameLb];
    self.appNameLb = nameLb;
    
    //detail describe
    UILabel *detailLb = [[UILabel alloc] initWithFrame:CGRectMake(nameLb.x, nameLb.maxY+kCurrentWidth(4), kCurrentWidth(140), kCurrentWidth(20))];
    detailLb.text = @"这回真是瞎了血本了…";
    detailLb.textColor = [UIColor colorWithHexString:@"333333"];
    detailLb.font = [UIFont fontWithName:RegularFontName size:kCurrentWidth(14)];
    [backV addSubview:detailLb];
    self.appDescribeLb = detailLb;
    
    //立即下载按钮
    UIButton *downloadBtn = [[UIButton alloc] initWithFrame:CGRectMake(backV.maxX-17-16-86, kCurrentWidth(28), kCurrentWidth(86), kCurrentWidth(39))];
    [downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    downloadBtn.backgroundColor = [UIColor colorWithHexString:@"#1789FF"];
    downloadBtn.layer.cornerRadius = kCurrentWidth(39/2);
    downloadBtn.clipsToBounds = YES;
    [backV addSubview:downloadBtn];
    self.downloadBtn = downloadBtn;
    [downloadBtn addTarget:self action:@selector(downloadClick:) forControlEvents:UIControlEventTouchUpInside];
    
}

/// MARK: set model
- (void)setModel:(MobiVideoEndModel *)model{
    _model = model;
    self.appNameLb.text = model.appDescribe;
    self.appDescribeLb.text = model.detailscribe;
    [self.logoImageV mobi_setImageWithURL:[NSURL URLWithString:model.bigIconUrl]];
    [self.bottomImgV mobi_setImageWithURL:[NSURL URLWithString:model.bigIconUrl]];
    [self.downloadBtn setTitle:model.buttonStr == nil ? @"下载" : model.buttonStr forState:UIControlStateNormal];
}

- (void)setLabelTitle:(NSString *)str skipType:(MobiSkipType)skipType{
    if (skipType == 8) {
        if ([str isEqualToString:@"0"]) {
            [self.jumpBtn setTitle:@"跳过" forState:UIControlStateNormal];
        } else {
            [self.jumpBtn setTitle:str forState:UIControlStateNormal];
        }
    } else {
        [self.jumpBtn setTitle:str forState:UIControlStateNormal];
    }
    
}

- (void)startVideoMobiSkipType:(MobiSkipType)skipType countdownTime:(CGFloat)duration{
    [self.jumpBtn setTitleWithSkipType:skipType duration:duration];
    [self.jumpBtn startRoundDispathTimerWithDuration:duration];
}

///跳过
- (void)jumpClick:(MobiVideoAdButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayingJumpClick)]) {
        [self.delegate videoPlayingJumpClick];
    }
}

///声音控制
- (void)speakClick:(UIButton *)button{
    button.selected = !button.selected;
    if (button.selected) {
        [button setImage:[UIImage imageNamed:MPResourcePathForResource(@"novoice")] forState:UIControlStateSelected];
    } else {
        [button setImage:[UIImage imageNamed:MPResourcePathForResource(@"喇叭")] forState:UIControlStateNormal];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayingMutedClick:)]) {
        [self.delegate videoPlayingMutedClick:button.selected];
    }
}

/// 下载
- (void)downloadClick:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayingDownloadLClick)]) {
        [self.delegate videoPlayingDownloadLClick];
    }
}

@end
