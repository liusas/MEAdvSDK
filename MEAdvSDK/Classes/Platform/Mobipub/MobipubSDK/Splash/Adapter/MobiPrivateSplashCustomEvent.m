//
//  MobiPrivateSplashCustomEvent.m
//  MobiPubSDK
//
//  Created by 卢镝 on 2020/7/9.
//

#import "MobiPrivateSplashCustomEvent.h"
#import "MobiLaunchAd.h"
#import "MobiConfig.h"
#import "MobiAdNativeImg.h"
#import "MobiSplashError.h"
#import <objc/runtime.h>

@interface MobiPrivateSplashCustomEvent()

@property (nonatomic) BOOL adAvailable;
@property (nonatomic, strong) MobiConfig *configuration;

@end

@interface MobiPrivateSplashCustomEvent (MobiLaunchAdDelegate) <MobiLaunchAdDelegate>

@end

@implementation MobiPrivateSplashCustomEvent

@dynamic delegate;

//- (NSString *)adUnitId
//{
//    return [self.delegate adUnitId];
//}

- (void)requestSplashWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup {

    MobiAdNativeBaseClass *nativeBase = configuration.nativeConfigData;
    MobiAdNativeImg *nativeImg = nativeBase.img[0];
    self.configuration = configuration;
    
    if (!nativeImg.url.length || nativeBase.styleType != 106) {
        NSError *error = [NSError splashErrorWithCode:MobiSplashAdErrorNoAdsAvailable localizedDescription:@"无效的开屏广告"];
        if ([self.delegate respondsToSelector:@selector(splashAdFailToPresentForCustomEvent:withError:)]) {
            [self.delegate splashAdFailToPresentForCustomEvent:self withError:error];
        }
        return;
    }
    
    [MobiLaunchAd downLoadImageAndCacheWithURLArray:[NSArray arrayWithObject:[NSURL URLWithString:nativeImg.url]] completed:^(NSArray * _Nonnull completedArray) {
        NSDictionary *dic = completedArray[0];
        if ([dic[@"result"] boolValue]) {
            self.adAvailable = YES;
            if ([self.delegate respondsToSelector:@selector(splashAdDidLoadForCustomEvent:)]) {
                [self.delegate splashAdDidLoadForCustomEvent:self];
            }
        } else {
            NSError *error = [NSError splashErrorWithCode:MobiSplashAdErrorNoAdReady localizedDescription:@"开屏广告加载失败"];
            if ([self.delegate respondsToSelector:@selector(splashAdFailToPresentForCustomEvent:withError:)]) {
                [self.delegate splashAdFailToPresentForCustomEvent:self withError:error];
            }
        }
    }];
}

- (void)presentSplashFromWindow:(UIWindow *)window {
    
    MobiAdNativeBaseClass *nativeBase = self.configuration.nativeConfigData;
    MobiAdNativeImg *nativeImg = nativeBase.img[0];
    
    //设置你工程的启动页使用的是:LaunchImage 还是 LaunchScreen.storyboard(不设置默认:LaunchImage)
//    [MobiLaunchAd setLaunchSourceType:MobiSourceTypeLaunchImage];
    
    //配置广告数据
    MobiLaunchImageAdConfiguration *imageAdconfiguration = [MobiLaunchImageAdConfiguration defaultConfiguration];
    imageAdconfiguration.window = window;
    imageAdconfiguration.imageNameOrURLString = nativeImg.url;
    imageAdconfiguration.openModel = nativeBase;
    //设置要添加的子视图(可选)
    //imageAdconfiguration.subViews = [self launchAdSubViews];
    //显示开屏广告
    [MobiLaunchAd imageAdWithImageAdConfiguration:imageAdconfiguration delegate:self];
}

- (BOOL)hasAdAvailable
{
    return self.adAvailable;
}

- (void)handleAdPlayedForCustomEventNetwork
{
    // no-op
}

- (void)handleCustomEventInvalidated
{
    [MobiLaunchAd removeAndAnimated:NO];
}

@end

//MARK: MobiLaunchAdDelegate

@implementation MobiPrivateSplashCustomEvent (MobiLaunchAdDelegate)

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdDidLoadForCustomEvent:)]) {
        [self.delegate splashAdDidLoadForCustomEvent:self];
    }
}

/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdSuccessPresentScreenForCustomEvent:)]) {
        [self.delegate splashAdSuccessPresentScreenForCustomEvent:self];
    }
}

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForLaunchAd:(MobiLaunchAd *)launchAd withError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(splashAdFailToPresentForCustomEvent:withError:)]) {
        [self.delegate splashAdFailToPresentForCustomEvent:self withError:error];
    }
}

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdApplicationWillEnterBackgroundForCustomEvent:)]) {
        [self.delegate splashAdApplicationWillEnterBackgroundForCustomEvent:self];
    }
}

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdExposuredForCustomEvent:)]) {
        [self.delegate splashAdExposuredForCustomEvent:self];
    }
}

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForLaunchAd:(MobiLaunchAd *)launchAd reportModel:(nonnull MobiLaunchAdReportModel *)model {
    
    self.configuration.clickDownPoint = model.clickDownPoint;
    self.configuration.clickUpPoint = model.clickUpPoint;
    
    if ([self.delegate respondsToSelector:@selector(splashAdClickedForCustomEvent:)]) {
        [self.delegate splashAdClickedForCustomEvent:self];
    }
}

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdWillClosedForCustomEvent:)]) {
        [self.delegate splashAdWillClosedForCustomEvent:self];
    }
}

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForLaunchAd:(MobiLaunchAd *)launchAd {
    
    self.adAvailable = NO;
    
    if ([self.delegate respondsToSelector:@selector(splashAdClosedForCustomEvent:)]) {
        [self.delegate splashAdClosedForCustomEvent:self];
    }
}

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdWillPresentFullScreenModalForCustomEvent:)]) {
        [self.delegate splashAdWillPresentFullScreenModalForCustomEvent:self];
    }
}

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdDidPresentFullScreenModalForCustomEvent:)]) {
        [self.delegate splashAdDidPresentFullScreenModalForCustomEvent:self];
    }
}

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdWillDismissFullScreenModalForCustomEvent:)]) {
        [self.delegate splashAdWillDismissFullScreenModalForCustomEvent:self];
    }
}

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd {
    
    if ([self.delegate respondsToSelector:@selector(splashAdDidDismissFullScreenModalForCustomEvent:)]) {
        [self.delegate splashAdDidDismissFullScreenModalForCustomEvent:self];
    }
}

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdCustomSkipView:(UIView * _Nullable)customSkipView LifeTime:(NSUInteger)time {
    
    if ([self.delegate respondsToSelector:@selector(splashAdLifeTime:)]) {
        [self.delegate splashAdLifeTime:self];
    }
}

@end
