//
//  MEGDTFeedRenderAdapter.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/1/7.
//  

#import "MEGDTFeedRenderAdapter.h"
#import <GDTUnifiedNativeAd.h>
#import "MEGDTCustomView.h" // 自渲染的view

@interface MEGDTFeedRenderAdapter () <GDTUnifiedNativeAdDelegate, GDTUnifiedNativeAdViewDelegate>

/// 是否需要展示
@property (nonatomic, assign) BOOL needShow;
@property (nonatomic, strong) GDTUnifiedNativeAd *unifiedNativeAd;
/// 信息流数据数组
@property (nonatomic, strong) NSArray <GDTUnifiedNativeAdDataObject *>*adDataArray;

@property (nonatomic, strong) MEGDTCustomView *adView;

@end

@implementation MEGDTFeedRenderAdapter

// MARK: - override
+ (instancetype)sharedInstance {
    static MEGDTFeedRenderAdapter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MEGDTFeedRenderAdapter alloc] init];
    });
    return sharedInstance;
}

/// 获取广告平台类型
- (MEAdAgentType)platformType{
    return MEAdAgentTypeGDT;
}

// MARK: - 信息流自渲染
/// 信息流预加载,并存入缓存
/// @param posId 广告位id
- (void)saveRenderFeedCacheWithPosId:(NSString *)posId {
    self.needShow = NO;
    self.isGetForCache = YES;
    self.posid = posId;
    
    self.unifiedNativeAd = [[GDTUnifiedNativeAd alloc] initWithAppId:[MEConfigManager sharedInstance].GDTAPPId placementId:@"6010690730057022"];
    self.unifiedNativeAd.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.unifiedNativeAd loadAd];
    });
}

/// 显示自渲染的信息流视图
- (BOOL)showRenderFeedViewWithPosId:(NSString *)posId {
    self.needShow = YES;
    self.posid = posId;
    
    // 初始化
    self.unifiedNativeAd = [[GDTUnifiedNativeAd alloc] initWithAppId:[MEConfigManager sharedInstance].GDTAPPId placementId:posId];//@"6010690730057022"
    self.unifiedNativeAd.delegate = self;
    [self.unifiedNativeAd loadAd];
    
    return YES;
}

/// 移除自渲染信息流视图
- (void)removeRenderFeedView {
    self.needShow = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.adView removeFromSuperview];
}

// MARK: - Other
/// 初始化自渲染view
- (void)initCustomAdView {
    if (!self.adDataArray.count) {
        return;
    }
    // 拉取下来的广告数据
    GDTUnifiedNativeAdDataObject *dataObject = self.adDataArray.firstObject;
    
    self.adView = [[MEGDTCustomView alloc] init];
    self.adView.delegate = self; // adView 广告回调
    self.adView.viewController = [self topVC]; // 跳转 VC
    CGFloat imageRate = 1280 / 720.f;
    if (dataObject.imageHeight > 0) {
        imageRate = dataObject.imageWidth / (CGFloat)dataObject.imageHeight;
    }
    self.adView.imageRate = imageRate;
    
    [self.adView setupWithUnifiedNativeAdObject:dataObject];
    [self.adView registerDataObject:dataObject clickableViews:@[self.adView.backView,
                                                                self.adView.clickButton,
                                                                self.adView.iconImageView,
                                                                self.adView.imageView]];
    if ([[dataObject callToAction] length] > 0) {
        [self.adView registerClickableCallToActionView:self.adView.CTAButton];
    }
    
    // 缓存拉取的广告
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetSuccess:feedViews:)]) {
        [self.feedDelegate adapterFeedCacheGetSuccess:self feedViews:@[self.adView]];
    }
    
    // 将生成的广告视图回调给上层
    if (self.needShow && self.isGetForCache == NO) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedRenderShowSuccess:feedView:)]) {
            [self.feedDelegate adapterFeedRenderShowSuccess:self feedView:self.adView];
        }
    } else {
        // 缓存拉取的广告
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetSuccess:feedViews:)]) {
            [self.feedDelegate adapterFeedCacheGetSuccess:self feedViews:@[self.adView]];
        }
    }
}

// MARK: - GDTUnifiedNativeAdDelegate
- (void)gdt_unifiedNativeAdLoaded:(NSArray<GDTUnifiedNativeAdDataObject *> *)unifiedNativeAdDataObjects error:(NSError *)error
{
    if (!error && unifiedNativeAdDataObjects.count > 0) {
        DLog(@"成功请求到广告数据");
        self.adDataArray = unifiedNativeAdDataObjects;
        // 拉取到广告数据, 初始化视图
        [self initCustomAdView];
        return;
    }
    
    if (error.code == 5004) {
        DLog(@"没匹配的广告，禁止重试，否则影响流量变现效果");
    } else if (error.code == 5005) {
        DLog(@"流量控制导致没有广告，超过日限额，请明天再尝试");
    } else if (error.code == 5009) {
        DLog(@"流量控制导致没有广告，超过小时限额");
    } else if (error.code == 5006) {
        DLog(@"包名错误");
    } else if (error.code == 5010) {
        DLog(@"广告样式校验失败");
    } else if (error.code == 3001) {
        DLog(@"网络错误");
    } else if (error.code == 5013) {
        DLog(@"请求太频繁，请稍后再试");
    } else if (error) {
        DLog(@"ERROR: %@", error);
    }
    
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
        [self.feedDelegate adapter:self bannerShowFailure:error];
    }
}

// MARK: - GDTUnifiedNativeAdViewDelegate
- (void)gdt_unifiedNativeAdViewDidClick:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
    DLog(@"%s",__FUNCTION__);
    DLog(@"%@ 广告被点击", unifiedNativeAdView.dataObject);
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClicked:)]) {
        [self.feedDelegate adapterFeedClicked:self];
    }
}

- (void)gdt_unifiedNativeAdViewWillExpose:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
    DLog(@"广告被曝光");
}

- (void)gdt_unifiedNativeAdDetailViewClosed:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
    DLog(@"%s",__FUNCTION__);
    DLog(@"广告详情页已关闭");
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClose:)]) {
        [self.feedDelegate adapterFeedClose:self];
    }
}

- (void)gdt_unifiedNativeAdViewApplicationWillEnterBackground:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
    DLog(@"%s",__FUNCTION__);
    DLog(@"广告进入后台");
}

- (void)gdt_unifiedNativeAdDetailViewWillPresentScreen:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
    DLog(@"%s",__FUNCTION__);
    DLog(@"广告详情页面即将打开");
}

- (void)gdt_unifiedNativeAdView:(GDTUnifiedNativeAdView *)unifiedNativeAdView playerStatusChanged:(GDTMediaPlayerStatus)status userInfo:(NSDictionary *)userInfo
{
    DLog(@"%s",__FUNCTION__);
    DLog(@"视频广告状态变更");
    switch (status) {
        case GDTMediaPlayerStatusInitial:
            DLog(@"视频初始化");
            break;
        case GDTMediaPlayerStatusLoading:
            DLog(@"视频加载中");
            break;
        case GDTMediaPlayerStatusStarted:
            DLog(@"视频开始播放");
            break;
        case GDTMediaPlayerStatusPaused:
            DLog(@"视频暂停");
            break;
        case GDTMediaPlayerStatusStoped:
            DLog(@"视频停止");
            break;
        case GDTMediaPlayerStatusError:
            DLog(@"视频播放出错");
        default:
            break;
    }
    if (userInfo) {
        long videoDuration = [userInfo[kGDTUnifiedNativeAdKeyVideoDuration] longValue];
        DLog(@"视频广告长度为 %ld s", videoDuration);
    }
}

@end
