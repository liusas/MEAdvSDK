//
//  XFVideoPlayController.m
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/10.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import "MobiXFVideoPlayController.h"
#import "MobiXFPlayer.h"
#import "MobiVideoEndView.h"
#import "MobiVideoPlayingView.h"
#import <StoreKit/SKStoreProductViewController.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height


@interface MobiXFVideoPlayController ()<MobiVideoEndViewDelegate,MobiVideoPlayingViewDelegate,SKStoreProductViewControllerDelegate,MobiXFPlayerDelegate>

@property (nonatomic, strong) MobiXFPlayer *player;
@property (nonatomic, strong) UIView *showView;
@property (nonatomic, strong) MobiVideoEndView *endView;
@property (nonatomic, strong) MobiVideoPlayingView *playingView;
@property (nonatomic, strong) UIImageView *lastImg;

@property (nonatomic,assign) CGFloat duration;

@end

@implementation MobiXFVideoPlayController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    /// 结束播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playToEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    /// 开始播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startPlay:) name:@"statusToPlay" object:nil];
    
    self.showView = [[UIView alloc] init];
    self.showView.backgroundColor = [UIColor whiteColor];
    self.showView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [self.view addSubview:self.showView];
    
    MobiAdVideoVideoAdm *nativeVideo = self.videoDataBase.videoAdm;
    MobiVideoEndModel *model = [[MobiVideoEndModel alloc] init];
    model.appName = nativeVideo.title;
    model.appDescribe = nativeVideo.desc;
    model.buttonStr = nativeVideo.button;
    model.bigIconUrl = nativeVideo.logo;
    
    self.endView.model = model;
    self.playingView.model = model;
    [self.view addSubview:self.endView];
    [self.view addSubview:self.playingView];
    
//    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
//    NSString *movePath =  [document stringByAppendingPathComponent:@"保存数据.mp4"];
//    NSURL *localURL = [NSURL fileURLWithPath:movePath];
//    NSURL *url2 = [NSURL URLWithString:@"https://dh2.v.netease.com/2017/cg/fxtpty.mp4"];
    [self.view addSubview:self.lastImg];
    [self.view bringSubviewToFront:self.endView];
    [[MobiXFPlayer sharedInstance] playWithUrl:self.contenURL showView:self.showView showType:self.playType];
    [MobiXFPlayer sharedInstance].delegate = self;
    
}

- (void)playWithCurrent:(CGFloat)current totalDuration:(CGFloat)tatalDuration playProgress:(CGFloat)playProgress{
//    NSLog(@"current == %.f,,,totalDuration == %.f,,,progress == %.2f",current,tatalDuration,playProgress);
    //self.duration = tatalDuration - current;
    //[self.playingView startVideoMobiSkipType:8 countdownTime:5];
    NSString *str = [NSString stringWithFormat:@"%.f",(tatalDuration - current)];
    [self.playingView setLabelTitle:str skipType:MobiSkipTypeRoundTime];
    
    if (playProgress == 0.25 || playProgress == 0.50 || playProgress == 0.75 || playProgress == 1.00) {
        
        if (playProgress == 0.25) {
            self.progressType = MobiVideoPlayFirst_Quarter_Play;
        } else if (playProgress == 0.50){
            self.progressType = MobiVideoPlayMid_play;
        } else if (playProgress == 0.75) {
            self.progressType = MobiVideoPlayThird_Quarter_Play;
        } else {
            self.progressType = MobiVideoPlayFinish_Play;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(mobiVideoPlayProgress:)]) {
            [self.delegate mobiVideoPlayProgress:self.progressType];
        }
    }
}


/// 结束播放
- (void)playToEnd{
    self.playingView.hidden = YES;
    self.endView.hidden = NO;
    self.lastImg.hidden = NO;
}

/// 开始播放
- (void)startPlay:(NSNotification *)noti{
    CGFloat duration = [noti.userInfo[@"duration"] floatValue];
    self.duration = duration;
    UIImage *img = [self getVideoPreViewImage:self.contenURL];
    self.lastImg.image = img;
    self.playingView.hidden = NO;
    //[self.playingView startVideoMobiSkipType:7 countdownTime:self.duration];
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoShowSuccess)]) {
        [self.delegate rewardedVideoShowSuccess];
    }
    [self postVideoPlayProess];
}

#pragma mark -- VideoEndViewDelegte
/// 关闭
- (void)videoCloseClick{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoCloseClick)]) {
        [self.delegate rewardedVideoCloseClick];
    }
}

/// 立即下载
- (void)videoDownloadClick{
    //do something
    [self toDownloadApp];
}

- (UIImage *)getVideoPreViewImage:(NSURL *)path {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(self.duration - 0.1, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}

- (void)postVideoPlayProess{
    __weak typeof(self)WeakSelf = self;
    __strong typeof(WeakSelf) strongSelf = WeakSelf;
    [self.player.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        //进度 当前时间/总时间
        CGFloat progress = CMTimeGetSeconds(WeakSelf.player.player.currentItem.currentTime) / CMTimeGetSeconds(WeakSelf.player.player.currentItem.duration);
        //在这里截取播放进度并处理
        if (progress == 1.0f) {
            //播放百分比为1表示已经播放完毕
        } else if (progress == 0.3) {
            
        }
    }];
}

#pragma mark -- VideoPlayingViewDelegate
/// 跳过
- (void)videoPlayingJumpClick{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 是否静音
- (void)videoPlayingMutedClick:(BOOL)isMuted{
    if (isMuted) {
        [MobiXFPlayer sharedInstance].isMuteds = YES;
    } else {
        [MobiXFPlayer sharedInstance].isMuteds = NO;
    }
}

- (void)videoPlayingDownloadLClick{
    //do something
    [self toDownloadApp];
}

- (void)toDownloadApp
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDownloadClick)]) {
        [self.delegate rewardedVideoDownloadClick];
    }
//    //首先实例化一个VC
//    SKStoreProductViewController *storeVC = [[SKStoreProductViewController alloc] init];
//    //然后设置代理，注意这很重要，不如弹出就没法dismiss了
//    storeVC.delegate = self;
//    //接着弹出VC
//    [self presentViewController:storeVC animated:YES completion:nil];
//    //最后加载应用数据
//    [storeVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:@"1525197855"} completionBlock:^(BOOL result, NSError * _Nullable error) {
//        if (error) {
//            //handle the error
//        }
//    }];
}

#pragma mark - SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    //在代理方法里dismiss这个VC
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

-(MobiVideoEndView *)endView{
    if (!_endView) {
        _endView = [[MobiVideoEndView alloc] init];
        _endView.delegate = self;
        _endView.hidden = YES;
    }
    return _endView;
}

- (MobiVideoPlayingView *)playingView{
    if (!_playingView) {
        _playingView = [[MobiVideoPlayingView alloc] init];
        _playingView.delegate = self;
        _playingView.hidden = YES;
    }
    return _playingView;
}

- (UIImageView *)lastImg{
    if (!_lastImg) {
        _lastImg = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _lastImg.hidden = YES;
    }
    return _lastImg;
}

@end
