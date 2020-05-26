//
//  MEGDTAdapter.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import "MEGDTAdapter.h"
#import <GDTNativeExpressAd.h>
#import <GDTNativeExpressAdView.h>
#import <GDTRewardVideoAd.h>
#import <GDTSplashAd.h>
#import <GDTUnifiedInterstitialAd.h>

@interface MEGDTAdapter ()<GDTNativeExpressAdDelegete, GDTRewardedVideoAdDelegate, GDTSplashAdDelegate, GDTUnifiedInterstitialAdDelegate>

// MARK: 信息流广告
@property (nonatomic, strong) NSMutableArray *expressAdViews;
/// 信息流模板广告
@property (nonatomic, strong) GDTNativeExpressAd *nativeExpressAd;

// MARK: 激励视频广告
@property (nonatomic, strong) GDTRewardVideoAd *rewardVideoAd;//激励视频广告

@property (strong, nonatomic) GDTSplashAd *splash;

@property (nonatomic, strong) GDTUnifiedInterstitialAd *interstitial;

/// 是否需要展示
@property (nonatomic, assign) BOOL needShow;

/// 是否展示误点按钮
@property (nonatomic, assign) BOOL showFunnyBtn;

@end

@implementation MEGDTAdapter

// MARK: - override
+ (instancetype)sharedInstance {
    static MEGDTAdapter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MEGDTAdapter alloc] init];
    });
    return sharedInstance;
}

/// 添加广告参数
- (void)setAdParams:(NSDictionary *)dicParam {
    
}

/// 获取广告平台类型
- (MEAdAgentType)platformType{
    return MEAdAgentTypeGDT;
}

// MARK: - 开屏广告
- (BOOL)showSplashWithPosid:(NSString *)posid {
    self.needShow = YES;
    self.posid = posid;
    
    GDTSplashAd *splash = [[GDTSplashAd alloc] initWithAppId:[MEConfigManager sharedInstance].GDTAPPId placementId:posid];
    splash.delegate = self;
    splash.fetchDelay = 3;
    [splash loadAdAndShowInWindow:[UIApplication sharedApplication].keyWindow];
    self.splash = splash;
    
    return YES;
}

/// 停止渲染开屏广告
- (void)stopSplashRender {
    self.needShow = NO;
    [self.splash loadAdAndShowInWindow:nil];
    self.splash = nil;
}

// MARK: - 插屏广告
- (BOOL)showInterstitialViewWithPosid:(NSString *)posid showFunnyBtn:(BOOL)showFunnyBtn {
    self.posid = posid;
    self.showFunnyBtn = showFunnyBtn;
    
    if (!self.interstitial && !self.interstitial.isAdValid) {
        self.needShow = YES;
        self.interstitial = [[GDTUnifiedInterstitialAd alloc] initWithAppId:[MEConfigManager sharedInstance].GDTAPPId placementId:posid];
        self.interstitial.delegate = self;
        self.interstitial.videoMuted = YES; // 设置视频是否Mute静音
        self.interstitial.videoAutoPlayOnWWAN = NO; // 设置视频是否在非 WiFi 网络自动播放
        [self.interstitial loadAd];
    } else {
        self.needShow = NO;
        [self.interstitial presentAdFromRootViewController:[self topVC]];
    }
    
    return YES;
}

// MARK: - 信息流广告
/// 信息流预加载,并存入缓存
/// @param feedWidth 信息流宽度
/// @param posId 广告位id
- (void)saveFeedCacheWithWidth:(CGFloat)feedWidth
                         posId:(NSString *)posId {
    self.needShow = NO;
    self.posid = posId;
    
    self.nativeExpressAd = [[GDTNativeExpressAd alloc] initWithAppId:[MEConfigManager sharedInstance].GDTAPPId
                                                         placementId:posId//@"5030722621265924"
                                                              adSize:CGSizeMake(feedWidth, 0)];
    self.nativeExpressAd.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.nativeExpressAd loadAd:1];
    });
}
/// 显示信息流视图
/// @param size 父视图size
/// @param posId 广告位id
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId {
    return [self showFeedViewWithWidth:feedWidth posId:posId withDisplayTime:0];
}

/// 显示信息流视图
/// @param size 父视图size
/// @param posId 广告位id
/// @param displayTime 展示时长,0表示不限制时长
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId
              withDisplayTime:(NSTimeInterval)displayTime {
    self.needShow = YES;
    self.posid = posId;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeExpressAd = [[GDTNativeExpressAd alloc] initWithAppId:[MEConfigManager sharedInstance].GDTAPPId
                                                             placementId:posId//@"5030722621265924"
                                                                  adSize:CGSizeMake(feedWidth, 0)];
        self.nativeExpressAd.delegate = self;
        [self.nativeExpressAd loadAd:1];
    });
    
    return YES;
}

/// 移除FeedView
- (void)removeFeedView {
    self.needShow = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showFeedViewTimeout) object:nil];
    [self.expressAdViews removeAllObjects];
}

// MARK: - 激励视频
- (BOOL)showRewardVideoWithPosid:(NSString *)posid {
    self.posid = posid;
    if (![self topVC]) {
        return NO;
    }
    
    if (self.isTheVideoPlaying == YES) {
        // 若当前有视频正在播放,则此次激励视频不播放
        return YES;
    }

    if (!self.rewardVideoAd || self.rewardVideoAd.isAdValid == NO) {
        self.rewardVideoAd = nil;
        self.needShow = YES;
        self.rewardVideoAd = [[GDTRewardVideoAd alloc] initWithAppId:[MEConfigManager sharedInstance].GDTAPPId placementId:posid];//8020744212936426
        self.rewardVideoAd.delegate = self;
        [self.rewardVideoAd loadAd];
    } else {
        self.needShow = NO;
        if ([[self topVC] isKindOfClass:NSClassFromString(@"GDTWebViewController")]) {
            return YES;
        }
        [self.rewardVideoAd showAdFromRootViewController:[self topVC]];
    }
    
    return YES;
}

/// 结束当前视频
- (void)stopCurrentVideo {
    self.needShow = NO;
    if (self.rewardVideoAd.adValid) {
        UIViewController *topVC = [self topVC];
        [topVC dismissViewControllerAnimated:YES completion:nil];
//        self.rewardVideoAd = nil;
    }
}

// MARK: - GDTNativeExpressAdDelegete
/**
 * 拉取广告成功的回调
 */
- (void)nativeExpressAdSuccessToLoad:(GDTNativeExpressAd *)nativeExpressAd views:(NSArray<__kindof GDTNativeExpressAdView *> *)views {
    self.expressAdViews = [NSMutableArray arrayWithArray:views];
    
    [self.expressAdViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        GDTNativeExpressAdView *expressView = (GDTNativeExpressAdView *)obj;
        expressView.controller = [self topVC];
        [expressView render];
        DLog(@"eCPM:%ld eCPMLevel:%@", [expressView eCPM], [expressView eCPMLevel]);
    }];
}

/**
 * 拉取广告失败的回调
 */
- (void)nativeExpressAdRenderFail:(GDTNativeExpressAdView *)nativeExpressAdView {
    DLog(@"信息流广告渲染失败");
    NSError *error = [NSError errorWithDomain:@"信息流广告渲染失败" code:1 userInfo:@{NSLocalizedDescriptionKey:@"广点通广告渲染失败"}];
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
        [self.feedDelegate adapter:self bannerShowFailure:error];
    }
}

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoad:(GDTNativeExpressAd *)nativeExpressAd error:(NSError *)error {
    DLog(@"信息流广告加载失败");
    if (self.isGetForCache == YES) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetFailed:)]) {
            [self.feedDelegate adapterFeedCacheGetFailed:error];
        }
        return;
    }
    
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
        [self.feedDelegate adapter:self bannerShowFailure:error];
    }
}

- (void)nativeExpressAdViewRenderSuccess:(GDTNativeExpressAdView *)nativeExpressAdView {
    DLog(@"广告视图渲染完成");
    if (self.needShow && self.isGetForCache == NO) {
        // 将广告视图添加到父视图
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedShowSuccess:feedView:)]) {
            [self.feedDelegate adapterFeedShowSuccess:self feedView:nativeExpressAdView];
        }
    } else {
        // 缓存拉取的广告
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetSuccess:feedViews:)]) {
            [self.feedDelegate adapterFeedCacheGetSuccess:self feedViews:@[nativeExpressAdView]];
        }
    }
}

- (void)nativeExpressAdViewClicked:(GDTNativeExpressAdView *)nativeExpressAdView {
    DLog(@"点击了信息流广告");
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClicked:)]) {
        [self.feedDelegate adapterFeedClicked:self];
    }
}

- (void)nativeExpressAdViewClosed:(GDTNativeExpressAdView *)nativeExpressAdView {
    DLog(@"%s",__FUNCTION__);
    [self.expressAdViews removeObject:nativeExpressAdView];
    DLog(@"关闭广告事件");
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClose:)]) {
        [self.feedDelegate adapterFeedClose:self];
    }
}


// MARK: - GDTRewardedVideoAdDelegate

- (void)gdt_rewardVideoAdDidLoad:(GDTRewardVideoAd *)rewardedVideoAd {
    DLog(@"%@ 广告数据加载成功", rewardedVideoAd.adNetworkName);
    DLog(@"eCPM:%ld eCPMLevel:%@", [rewardedVideoAd eCPM], [rewardedVideoAd eCPMLevel]);
    
    if (self.needShow) {
        if ([[self topVC] isKindOfClass:NSClassFromString(@"GDTWebViewController")]) {
            return;
        }
        self.isTheVideoPlaying = YES;
        [self.rewardVideoAd showAdFromRootViewController:[self topVC]];
    }
}


- (void)gdt_rewardVideoAdVideoDidLoad:(GDTRewardVideoAd *)rewardedVideoAd {
    NSError *error = nil;
    if (self.rewardVideoAd.expiredTimestamp <= [[NSDate date] timeIntervalSince1970]) {
        DLog(@"广告已过期，请重新拉取");
        error = [NSError errorWithDomain:@"广告已过期，请重新拉取" code:1 userInfo:@{@"广告平台":rewardedVideoAd.adNetworkName}];
        
        if (self.isTheVideoPlaying == NO && self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
            [self.videoDelegate adapter:self videoShowFailure:error];
        }
        return;
    }
    if (!self.rewardVideoAd.isAdValid) {
        DLog(@"广告失效，请重新拉取");
        error = [NSError errorWithDomain:@"广告失效，请重新拉取" code:1 userInfo:@{@"广告平台":rewardedVideoAd.adNetworkName}];
        if (self.isTheVideoPlaying == NO && self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
            [self.videoDelegate adapter:self videoShowFailure:error];
        }
        return;
    }
    
    DLog(@"%@ 视频文件加载成功", rewardedVideoAd.adNetworkName);
}


- (void)gdt_rewardVideoAdWillVisible:(GDTRewardVideoAd *)rewardedVideoAd {
    DLog(@"视频播放页即将打开");
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoShowSuccess:)]) {
        [self.videoDelegate adapterVideoShowSuccess:self];
    }
}

- (void)gdt_rewardVideoAdDidExposed:(GDTRewardVideoAd *)rewardedVideoAd {
    DLog(@"%@ 广告已曝光", rewardedVideoAd.adNetworkName);
}

- (void)gdt_rewardVideoAdDidClose:(GDTRewardVideoAd *)rewardedVideoAd {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClose:)]) {
        [self.videoDelegate adapterVideoClose:self];
    }
    self.isTheVideoPlaying = NO;
    self.needShow = NO;
    // 预加载
    [rewardedVideoAd loadAd];
}


- (void)gdt_rewardVideoAdDidClicked:(GDTRewardVideoAd *)rewardedVideoAd {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClicked:)]) {
        [self.videoDelegate adapterVideoClicked:self];
    }
}

- (void)gdt_rewardVideoAd:(GDTRewardVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    if (error.code == 4014) {
        DLog(@"请拉取到广告后再调用展示接口");
    } else if (error.code == 4016) {
        DLog(@"应用方向与广告位支持方向不一致");
    } else if (error.code == 5012) {
        DLog(@"广告已过期");
    } else if (error.code == 4015) {
        DLog(@"广告已经播放过，请重新拉取");
    } else if (error.code == 5002) {
        DLog(@"视频下载失败");
    } else if (error.code == 5003) {
        DLog(@"视频播放失败");
    } else if (error.code == 5004) {
        DLog(@"没有合适的广告");
    } else if (error.code == 5013) {
        DLog(@"请求太频繁，请稍后再试");
    } else if (error.code == 3002) {
        DLog(@"网络连接超时");
    } else {
        DLog(@"未知错误,联系腾讯商务解决");
    }
    
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
        [self.videoDelegate adapter:self videoShowFailure:error];
    }
}

- (void)gdt_rewardVideoAdDidRewardEffective:(GDTRewardVideoAd *)rewardedVideoAd {
    DLog(@"播放时长达到激励条件");
}

- (void)gdt_rewardVideoAdDidPlayFinish:(GDTRewardVideoAd *)rewardedVideoAd {
    DLog(@"视频播放结束");
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoFinishPlay:)]) {
        [self.videoDelegate adapterVideoFinishPlay:self];
    }
}

// MARK: - GDTSplashAdDelegate
-(void)splashAdSuccessPresentScreen:(GDTSplashAd *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashShowSuccess:)]) {
        [self.splashDelegate adapterSplashShowSuccess:self];
    }
    
    [GDTSplashAd preloadSplashOrderWithAppId:[MEConfigManager sharedInstance].GDTAPPId placementId:self.posid];
}

- (void)splashAdDidLoad:(GDTSplashAd *)splashAd {
    
}

-(void)splashAdFailToPresent:(GDTSplashAd *)splashAd withError:(NSError *)error {
    self.splash = nil;
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapter:splashShowFailure:)]) {
        [self.splashDelegate adapter:self splashShowFailure:error];
    }
}

- (void)splashAdWillClosed:(GDTSplashAd *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClose:)]) {
        [self.splashDelegate adapterSplashClose:self];
    }
    self.splash = nil;
}

-(void)splashAdClosed:(GDTSplashAd *)splashAd {
    self.splash = nil;
}


- (void)splashAdExposured:(GDTSplashAd *)splashAd
{
    DLog(@"%s",__FUNCTION__);
}

- (void)splashAdWillDismissFullScreenModal:(GDTSplashAd *)splashAd
{
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashDismiss:)]) {
        [self.splashDelegate adapterSplashDismiss:self];
    }
}

- (void)splashAdDidDismissFullScreenModal:(GDTSplashAd *)splashAd
{
     DLog(@"%s",__FUNCTION__);
}

- (void)splashAdClicked:(GDTSplashAd *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClicked:)]) {
        [self.splashDelegate adapterSplashClicked:self];
    }
}

// MARK: - GDTUnifiedInterstitialAdDelegate
/**
 *  插屏2.0广告预加载成功回调
 *  当接收服务器返回的广告数据成功后调用该函数
 */
- (void)unifiedInterstitialSuccessToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial
{
    if (self.needShow) {
        [self.interstitial presentAdFromRootViewController:[self topVC]];
    }
}

/**
 *  插屏2.0广告预加载失败回调
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedInterstitialFailToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
        [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
    }
}

/**
 *  插屏2.0广告将要展示回调
 *  插屏2.0广告即将展示回调该函数
 */
- (void)unifiedInterstitialWillPresentScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialLoadSuccess:)]) {
        [self.interstitialDelegate adapterInterstitialLoadSuccess:self];
    }
    
    UIViewController *vc = [self topVC];
    if (vc.view.subviews.count && self.showFunnyBtn == YES) {
        UIView *view = vc.view.subviews[0];
        CGRect frame = view.frame;
        CGFloat buttonWidth = 22.f;
        self.funnyButton = [[MEFunnyButton alloc] initWithFrame:CGRectMake(view.frame.size.width-buttonWidth-5.f, view.frame.size.height-buttonWidth-10, buttonWidth, buttonWidth)];
        [view addSubview:self.funnyButton];
    }
}

/**
 *  插屏2.0广告展示结束回调
 *  插屏2.0广告展示结束回调该函数
 */
- (void)unifiedInterstitialDidDismissScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialCloseFinished:)]) {
        [self.interstitialDelegate adapterInterstitialCloseFinished:self];
    }
    
    self.needShow = NO;
    // 广告预加载
    [self.interstitial loadAd];
    [self.funnyButton removeFromSuperview];
}

- (void)unifiedInterstitialFailToPresent:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
    DLog(@"插屏广告展示失败 error = %@", error);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
        [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
    }
}

/**
 *  插屏2.0广告点击回调
 */
- (void)unifiedInterstitialClicked:(GDTUnifiedInterstitialAd *)unifiedInterstitial
{
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialClicked:)]) {
        [self.interstitialDelegate adapterInterstitialClicked:self];
    }
}

/**
 *  全屏广告页将要关闭
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial
{
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialDismiss:)]) {
        [self.interstitialDelegate adapterInterstitialDismiss:self];
    }
}


// MARK: - Private
- (void)showFeedViewTimeout {
    self.needShow = NO;
    // 清空所有广告视图
    [self.expressAdViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        GDTNativeExpressAdView *expressView = (GDTNativeExpressAdView *)obj;
        [expressView removeFromSuperview];
        expressView = nil;
    }];
    [self.expressAdViews removeAllObjects];
    
//    NSError *error = [NSError errorWithDomain:@"BUADError" code:0 userInfo:@{NSLocalizedDescriptionKey: @"请求超时"}];
}

- (BOOL)shouldAutorotate {
    return YES;
}
@end
