//
//  MobiPrivateFeedCustomEvent.m
//  MobiPubSDK
//
//  Created by 卢镝 on 2020/7/29.
//

#import "MobiPrivateFeedCustomEvent.h"
#import "MobiNativeExpressFeedView.h"
#import "MobiNativeExpressFeedView+MobiFeedView.h"
#import "MobiLaunchAd.h"
#import "MobiConfig.h"
#import "MobiAdNativeImg.h"
#import "MobiFeedError.h"

@interface MobiPrivateFeedCustomEvent ()

@property (nonatomic) BOOL adAvailable;
@property (nonatomic, strong) MobiConfig *configuration;

@end

@interface MobiPrivateFeedCustomEvent (MobiNativeExpressFeedViewDelegate) <MobiNativeExpressFeedViewDelegate>

@end

@implementation MobiPrivateFeedCustomEvent

- (void)requestFeedWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup {
    
    MobiAdNativeBaseClass *nativeBase = configuration.nativeConfigData;
    self.configuration = configuration;
    
    if (!nativeBase.img.count || nativeBase.styleType != 102) {
        NSError *error = [NSError feedErrorWithCode:MobiFeedAdErrorNoAdsAvailable localizedDescription:@"无效的信息流广告"];
        if ([self.delegate respondsToSelector:@selector(nativeExpressAdFailToLoadForCustomEvent:error:)]) {
            [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
        }
        return;
    }
    
    NSArray *urlArray;
    
    if (nativeBase.style == 10201) {//信息流:单图480*360,一级样式id:102,二级样式id:10201,素材描述主图：480*360、标题、描述
        MobiAdNativeImg *nativeImg = nativeBase.img[0];
        NSURL *url = [NSURL URLWithString:nativeImg.url];
        urlArray = [NSArray arrayWithObject:url];
    }else if (nativeBase.style == 10211) {//信息流:三图480*360,一级样式id:102,二级样式id:10211,主图：480*360 X 3、标题、描述
        NSMutableArray *mutArray = [NSMutableArray array];
        for (int i = 0; i < 3; i++) {
            MobiAdNativeImg *nativeImg = nativeBase.img[i];
            NSURL *url = [NSURL URLWithString:nativeImg.url];
            if (![mutArray containsObject:url]) {//判断数组中的链接是否有重复的链接，没有则添加
                [mutArray addObject:url];
            }
        }
        urlArray = mutArray;
    }
    
    //下载并缓存图片数组
    [self downLoadImageAndCacheWithURLArray:urlArray nativeBaseClass:nativeBase];
}

///下载并缓存图片数组
- (void)downLoadImageAndCacheWithURLArray:(NSArray *)urlArray nativeBaseClass:(MobiAdNativeBaseClass *)nativeBase {
    
    [MobiLaunchAd downLoadImageAndCacheWithURLArray:urlArray completed:^(NSArray * _Nonnull completedArray) {
        
        if (nativeBase.style == 10201) {//信息流:单图480*360,一级样式id:102,二级样式id:10201,素材描述主图：480*360、标题、描述
            NSDictionary *dic = completedArray[0];
            if ([dic[@"result"] boolValue]) {
                //创建信息流广告
                [self createFeedViewWithNativeBaseClass:nativeBase];
            }else {
                NSError *error = [NSError feedErrorWithCode:MobiFeedAdErrorNoAdReady localizedDescription:@"信息流广告加载失败"];
                if ([self.delegate respondsToSelector:@selector(nativeExpressAdFailToLoadForCustomEvent:error:)]) {
                    [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
                }
            }
        }else if (nativeBase.style == 10211) {//信息流:三图480*360,一级样式id:102,二级样式id:10211,主图：480*360 X 3、标题、描述
            [completedArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {//此处判断是否所有的图片都已经下载成功了，不成功则报错
                NSDictionary *dic = (NSDictionary *)obj;
                if (![dic[@"result"] boolValue]) {
                    NSError *error = [NSError feedErrorWithCode:MobiFeedAdErrorNoAdReady localizedDescription:@"信息流广告加载失败"];
                    if ([self.delegate respondsToSelector:@selector(nativeExpressAdFailToLoadForCustomEvent:error:)]) {
                        [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
                    }
                    return;
                }
            }];
            //创建信息流广告
            [self createFeedViewWithNativeBaseClass:nativeBase];
        }
    }];
}

///图片下载成功后，创建信息流广告
- (void)createFeedViewWithNativeBaseClass:(MobiAdNativeBaseClass *)nativeBase {
    
    self.adAvailable = YES;
    //创建信息流广告视图
    MobiNativeExpressFeedView *feedView = [[MobiNativeExpressFeedView alloc] initWithNativeExpressFeedViewSize:self.configuration.feedSize delegate:self];
    
    NSArray *views = [NSArray arrayWithObject:feedView];
    if ([self.delegate respondsToSelector:@selector(nativeExpressAdSuccessToLoadForCustomEvent:views:)]) {
        [self.delegate nativeExpressAdSuccessToLoadForCustomEvent:self views:views];
    }
    
    //填充数据并自适应信息流广告高度
    [feedView refreshUIWithNativeBaseClass:nativeBase];
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
   
}

@end


//MARK: MobiNativeExpressFeedViewDelegate

@implementation MobiPrivateFeedCustomEvent (MobiNativeExpressFeedViewDelegate)

/*
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderSuccessForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewRenderSuccessForCustomEvent:nativeExpressAdView];
    }
}

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderFailForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewRenderFailForCustomEvent:nativeExpressAdView];
    }
}

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewExposureForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewExposureForCustomEvent:nativeExpressAdView];
    }
}

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView reportModel:(MobiFeedAdReportModel *)model {
    
    self.configuration.clickDownPoint = model.clickDownPoint;
    self.configuration.clickUpPoint = model.clickUpPoint;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewClickedForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewClickedForCustomEvent:nativeExpressAdView];
    }
}

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
}


/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewWillPresentScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewWillPresentScreenForCustomEvent:nativeExpressAdView];
    }
    
}

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewDidPresentScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewDidPresentScreenForCustomEvent:nativeExpressAdView];
    }
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewWillDissmissScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewWillDissmissScreenForCustomEvent:nativeExpressAdView];
    }
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForFeedView:(MobiNativeExpressFeedView *)nativeExpressAdView {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewDidDissmissScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewDidDissmissScreenForCustomEvent:nativeExpressAdView];
    }
}

@end
