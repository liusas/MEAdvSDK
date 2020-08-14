//
//  VideoEndView.m
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/15.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import "MobiVideoEndView.h"
#import "MobiVideoAppConfig.h"
#import "UIView+MobiFrame.h"
#import "UIColor+MobiBaseFramework.h"
#import "MobiLaunchAdImageView.h"
#import "MobiGlobal.h"

@interface MobiVideoEndView ()

@property (nonatomic, strong) UIView *bgView;//背景
///close button
@property (nonatomic, strong) UIButton *closeBtn;
///APP's logo
@property (nonatomic, strong) MobiLaunchAdImageView *appIcon;
///app describe
@property (nonatomic, strong) UILabel *appDescribe;
///app detail describe
@property (nonatomic, strong) UILabel *detailDescribe;
///download button
@property (nonatomic, strong) UIButton *downloadBtn;
@end

@implementation MobiVideoEndView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.57];
        self.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        [self createUI];
    }
    return self;
}

- (void)createUI{
    //close button
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(kCurrentWidth(37), kCurrentWidth(5)+iPhoneStatusBarHeight, kCurrentWidth(32), kCurrentWidth(32))];
    [closeBtn setImage:[UIImage imageNamed:MPResourcePathForResource(@"close")] forState:UIControlStateNormal];
    [self addSubview:closeBtn];
    [closeBtn addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
    //logo
    MobiLaunchAdImageView *logo = [[MobiLaunchAdImageView alloc] init];
    logo.frame = CGRectMake(kCurrentWidth(137), kCurrentWidth(44)+iPhoneStatusBarAndNavigationBarHeight, kCurrentWidth(102), kCurrentWidth(102));
    logo.layer.cornerRadius = kCurrentWidth(21);
    logo.clipsToBounds = YES;
    [self addSubview:logo];
    self.appIcon = logo;
    //decribe
    UILabel *topLb = [[UILabel alloc] initWithFrame:CGRectMake(kCurrentWidth(41), logo.maxY+kCurrentWidth(39), kCurrentWidth(293), kCurrentWidth(53))];
    topLb.text = @"这回真是瞎了血本了赶紧下载啊啊我要凑够两行…";
    topLb.textColor = [UIColor whiteColor];
    topLb.font = [UIFont fontWithName:MediumFontName size:kCurrentWidth(18)];
    topLb.numberOfLines = 2;
    topLb.textAlignment = NSTextAlignmentCenter;
    [self addSubview:topLb];
    self.appDescribe = topLb;
    
    //detail describe
    UILabel *detailLb = [[UILabel alloc] initWithFrame:CGRectMake(kCurrentWidth(41), topLb.maxY+kCurrentWidth(9), kCurrentWidth(293), kCurrentWidth(25))];
    detailLb.text = @"据说这个游戏能发财，朋友们赶紧来玩啊！";
    detailLb.textColor = [UIColor whiteColor];
    detailLb.font = [UIFont fontWithName:RegularFontName size:kCurrentWidth(14)];
    detailLb.textAlignment = NSTextAlignmentCenter;
    [self addSubview:detailLb];
    self.detailDescribe = detailLb;
    
    for (int i = 0; i < 5; i ++) {
        UIImageView *img = [[UIImageView alloc] init];
        img.frame = CGRectMake(kCurrentWidth(62) + kCurrentWidth(14 + 39) * i, kCurrentWidth(104) + detailLb.maxY, kCurrentWidth(39), kCurrentWidth(37));
        //img.backgroundColor = [UIColor orangeColor];
        img.image = [UIImage imageNamed:@"星形"];
        [self addSubview:img];
    }
    
    //立即下载按钮
    UIButton *downloadBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, kCurrentWidth(467) + iPhoneStatusBarAndNavigationBarHeight, kCurrentWidth(261), kCurrentWidth(55))];
    [downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    downloadBtn.backgroundColor = [UIColor colorWithHexString:@"#1789FF"];
    downloadBtn.centerX = self.centerX;
    downloadBtn.layer.cornerRadius = kCurrentWidth(55/2);
    downloadBtn.clipsToBounds = YES;
    [self addSubview:downloadBtn];
    self.downloadBtn = downloadBtn;
    [downloadBtn addTarget:self action:@selector(downloadClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setModel:(MobiVideoEndModel *)model{
    _model = model;
    [self.appIcon mobi_setImageWithURL:[NSURL URLWithString:model.bigIconUrl]];
    self.appDescribe.text = model.appDescribe;
    self.detailDescribe.text = model.detailscribe;
    [self.downloadBtn setTitle:model.buttonStr == nil ? @"下载" : model.buttonStr forState:UIControlStateNormal];
}

//赋值
- (void)showViewWithModel:(MobiVideoEndModel *)model{
    
}

//关闭视频
- (void)closeClick:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoCloseClick)]) {
        [self.delegate videoCloseClick];
    }
}
/// 立即下载
- (void)downloadClick:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDownloadClick)]) {
        [self.delegate videoDownloadClick];
    }
}

//block模式
-(void)asyncDownloadWithConnectionBlock:(NSString *)requestUrl imageView:(UIImageView *)imageView
{
    //显示加载圈
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
 
    //1.将字符串地址转换成URL
    NSURL *url = [NSURL URLWithString:requestUrl];
    //2.将URL封装成NSURLRequest对象，可被Connection使用
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"%@",[NSThread currentThread]);
    NSLog(@"开始请求");
    [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 200){
            UIImage *image = [UIImage imageWithData:data];
            imageView.image = image;
        }
    }];
}


@end
