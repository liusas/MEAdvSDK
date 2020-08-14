//
//  MobiPrivateInterstitialCustomEvent.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/8/11.
//

#import "MobiPrivateInterstitialCustomEvent.h"
#import "MobiInterstitialShowVC.h"
#import "MobiLaunchAd.h"
#import "MobiConfig.h"
#import "MPError.h"

@interface MobiPrivateInterstitialCustomEvent ()<MPInterstitialViewControllerDelegate>

@property (nonatomic) BOOL adAvailable;
@property (nonatomic, strong) MobiConfig *configuration;

@end

@implementation MobiPrivateInterstitialCustomEvent

- (void)requestInterstitialWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup
{
    MobiAdNativeBaseClass *nativeBase = configuration.nativeConfigData;
    MobiAdNativeImg *nativeImg = nativeBase.img[0];
    self.configuration = configuration;
    
    if (!nativeImg.url.length || nativeBase.styleType != MobiAdTypeInterstitial) {
        NSError *error = [NSError errorWithCode:MOPUBErrorNoInventory localizedDescription:@"无效插屏广告"];
        if ([self.delegate respondsToSelector:@selector(interstitialCustomEvent:didFailToLoadAdWithError:)]) {
            [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
        }
        return;
    }
    
    // 下载图片
    [MobiLaunchAd downLoadImageAndCacheWithURLArray:[NSArray arrayWithObject:[NSURL URLWithString:nativeImg.url]] completed:^(NSArray * _Nonnull completedArray) {
        NSDictionary *dic = completedArray[0];
        if ([dic[@"result"] boolValue]) {
            self.adAvailable = YES;
            if ([self.delegate respondsToSelector:@selector(interstitialCustomEvent:didLoadAd:)]) {
                [self.delegate interstitialCustomEvent:self didLoadAd:nil];
            }
        } else {
            NSError *error = [NSError errorWithCode:MOPUBErrorAdUnitWarmingUp localizedDescription:@"插屏广告资源加载失败"];
            if ([self.delegate respondsToSelector:@selector(interstitialCustomEvent:didFailToLoadAdWithError:)]) {
                [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
            }
        }
    }];
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return YES;
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    if (self.adAvailable) {
        MobiAdNativeBaseClass *nativeBase = self.configuration.nativeConfigData;
        MobiAdNativeImg *nativeImg = nativeBase.img[0];
        
        MobiInterstitialShowVC *adVC = [MobiInterstitialShowVC new];
        adVC.delegate = self;
        adVC.imgUrl = nativeImg.url;
        adVC.width = nativeImg.w.doubleValue;
        adVC.height = nativeImg.h.doubleValue;
        adVC.configuration = self.configuration;
        
        if ([self.delegate respondsToSelector:@selector(interstitialCustomEventWillAppear:)]) {
            [self.delegate interstitialCustomEventWillAppear:self];
        }
        [adVC presentInterstitialFromViewController:rootViewController complete:^(NSError *error) {
            if (error) {
                return;
            }
            
            if ([self.delegate respondsToSelector:@selector(interstitialCustomEventDidAppear:)]) {
                [self.delegate interstitialCustomEventDidAppear:self];
            }
        }];
    }
}


// MARK: - MPInterstitialViewControllerDelegate
- (void)interstitialDidLoadAd:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:didLoadAd:)]) {
        [self.delegate interstitialCustomEvent:self didLoadAd:nil];
    }
}

- (void)interstitialDidFailToLoadAd:(id<MPInterstitialViewController>)interstitial error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:didFailToLoadAdWithError:)]) {
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
    }
}

- (void)interstitialWillAppear:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillAppear:)]) {
        [self.delegate interstitialCustomEventWillAppear:self];
    }
}

- (void)interstitialDidAppear:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidAppear:)]) {
        [self.delegate interstitialCustomEventDidAppear:self];
    }
}

- (void)interstitialWillDisappear:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillDisappear:)]) {
        [self.delegate interstitialCustomEventWillDisappear:self];
    }
}

- (void)interstitialDidDisappear:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidDisappear:)]) {
        [self.delegate interstitialCustomEventDidDisappear:self];
    }
}

- (void)interstitialDidReceiveTapEvent:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidReceiveTapEvent:)]) {
        [self.delegate interstitialCustomEventDidReceiveTapEvent:self];
    }
}

- (void)interstitialWillLeaveApplication:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillLeaveApplication:)]) {
        [self.delegate interstitialCustomEventWillLeaveApplication:self];
    }
}

- (void)interstitialWillPresentModal:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillPresentModal:)]) {
        [self.delegate interstitialCustomEventWillPresentModal:self];
    }
}

- (void)interstitialDidDismissModal:(id<MPInterstitialViewController>)interstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidDismissModal:)]) {
        [self.delegate interstitialCustomEventDidDismissModal:self];
    }
}


@end
