//
//  MobiPrivateRewardedVideoCustomEvent.m
//  MobiPubSDK
//
//  Created by 李新丰 on 2020/8/6.
//

#import "MobiPrivateRewardedVideoCustomEvent.h"
#import "MobiConfig.h"
#import "MobiAdVideoBaseClass.h"
#import "MobiRewardedVideoError.h"
#import "MobiVideoAdManager.h"

@interface MobiPrivateRewardedVideoCustomEvent ()<MobiVideoAdManagerDelegate>

@property (nonatomic) BOOL adAvailable;
@property (nonatomic, strong) MobiConfig *configuration;

@end


@interface MobiPrivateRewardedVideoCustomEvent (MobiVideoDelegate)<MobiPrivateRewardedVideoCustomEventDelegate>

@end


@implementation MobiPrivateRewardedVideoCustomEvent

@dynamic delegate;

- (void)requestRewardedVideoWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup{
    MobiAdVideoBaseClass *nativeBase = configuration.videoConfigData;
    MobiAdVideoVideoAdm *nativeVideo = nativeBase.videoAdm;
    self.configuration = configuration;
    
    if (!nativeVideo.videoUrl.length) {
        NSError *error = [NSError rewardVideoErrorWithCode:MobiRewardedVideoAdErrorNoAdsAvailable localizedDescription:@"没有有效视频"];
        if ([self.delegate respondsToSelector:@selector(rewardedVideoDidFailToLoadAdForCustomEvent:error:)]) {
            [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
        }
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(rewardedVideoDidLoadAdForCustomEvent:)]) {
        [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
    }
    
    [MobiVideoAdManager downLoadVideoAndCacheWithURLArray:[NSArray arrayWithObject:[NSURL URLWithString:nativeVideo.videoUrl]] completed:^(NSArray * _Nonnull completedArray) {
        NSDictionary *dic = completedArray[0];
        if ([dic[@"result"] boolValue]) {
            self.adAvailable = YES;
            if ([self.delegate respondsToSelector:@selector(rewardedVideoAdVideoDidLoadForCustomEvent:)]) {
                [self.delegate rewardedVideoAdVideoDidLoadForCustomEvent:self];
            }
        } else {
            NSError *error = [NSError rewardVideoErrorWithCode:MobiRewardedVideoAdErrorUnknown localizedDescription:@"广告加载失败"];
            if ([self.delegate respondsToSelector:@selector(rewardedVideoDidFailToLoadAdForCustomEvent:error:)]) {
                [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
            }
        }
    }];
}

- (BOOL)hasAdAvailable{
    return self.adAvailable;
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController{
    
    
//    MobiAdNativeBaseClass *nativeBase = self.configuration.nativeConfigData;
//    MobiAdNativeImg *nativeImg = nativeBase.img[0];
    
    MobiAdVideoBaseClass *nativeBase = self.configuration.videoConfigData;
    MobiAdVideoVideoAdm *nativeVideo = nativeBase.videoAdm;
    
    MobiVideoAdManager *manager = [MobiVideoAdManager shareManager];
    manager.controller = viewController;
    manager.videoDataBase = nativeBase;
    //配置广告数据
    MobiVideoAdConfiguration *configuration = [MobiVideoAdConfiguration defaultConfiguration];
    configuration.videoNameOrURLString = nativeVideo.videoUrl;
    configuration.openModel = nativeBase;
    //设置要添加的子视图(可选)
    //imageAdconfiguration.subViews = [self launchAdSubViews];
    //显示开屏广告
    [MobiVideoAdManager videoAdWithVideoAdConfiguration:configuration delegate:self];
}

#pragma mark -- MobiVideoAdManagerDelegate --

- (void)rewardedVideo:(MobiVideoAdManager *)videoAd didLoadAdSuccess:(NSURL *)pathUrl{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidLoadAdForCustomEvent:)]) {
        [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
    }
}

- (void)rewardedVideoDidLoadAdFailed:(MobiVideoAdManager *)videoAd{
    self.adAvailable = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidFailToLoadAdForCustomEvent:error:)]) {
        [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:nil];
    }
}

- (void)rewardedVideoShowSuccess:(MobiVideoAdManager *)videoAd{
    self.adAvailable = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoWillAppearForCustomEvent:)]) {
        [self.delegate rewardedVideoWillAppearForCustomEvent:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidAppearForCustomEvent:)]) {
        [self.delegate rewardedVideoDidAppearForCustomEvent:self];
    }
}

- (void)rewardedVideoShowFailed:(MobiVideoAdManager *)videoAd{
    self.adAvailable = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidFailToPlayForCustomEvent:error:)]) {
        [self.delegate rewardedVideoDidFailToPlayForCustomEvent:self error:nil];
    }
}

- (void)rewardedVideoCloseClick:(MobiVideoAdManager *)videoAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidDisappearForCustomEvent:)]) {
        [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
    }
}

- (void)rewardedVideoDownloadClick:(MobiVideoAdManager *)videoAd{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDidReceiveTapEventForCustomEvent:)]) {
        [self.delegate rewardedVideoDidReceiveTapEventForCustomEvent:self];
    }
}

- (void)rewardedVideoWillLeaveApp:(MobiVideoAdManager *)videoAd{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoWillLeaveApplicationForCustomEvent:)]) {
        [self.delegate rewardedVideoWillLeaveApplicationForCustomEvent:self];
    }
}

- (void)mobiVideoAd:(MobiVideoAdManager *)videoAd videoPlayProgress:(MobiVideoPlayProgressType)progress {
    MobiAdVideoBaseClass *nativeBase = self.configuration.videoConfigData;
    MobiAdVideoVideoAdm *nativeVideo = nativeBase.videoAdm;
    NSArray *trackArr = nil;
    if (progress == MobiVideoPlayFirst_Quarter_Play) {
        trackArr = [NSArray arrayWithArray:nativeVideo.firstQuarterPlay];
    } else if (progress == MobiVideoPlayMid_play) {
        trackArr = [NSArray arrayWithArray:nativeVideo.midPlay];
    } else if (progress == MobiVideoPlayThird_Quarter_Play) {
        trackArr = [NSArray arrayWithArray:nativeVideo.thirdQuarterPlay];
    } else if (progress == MobiVideoPlayFinish_Play) {
        trackArr = [NSArray arrayWithArray:nativeVideo.finishPlay];
    }
    
    if (trackArr != nil) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(trackProgressImpressionWithUrlArr:)]) {
            [self.delegate trackProgressImpressionWithUrlArr:trackArr];
        }
    }
}
@end
