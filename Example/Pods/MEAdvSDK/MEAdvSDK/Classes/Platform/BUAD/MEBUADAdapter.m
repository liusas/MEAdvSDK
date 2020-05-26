//
//  MEBUADAdapter.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import "MEBUADAdapter.h"
#import <BUAdSDK/BUNativeExpressAdManager.h>
#import <BUAdSDK/BUNativeExpressAdView.h>
#import <BUAdSDK/BUAdSDK.h>
#import <BUAdSDK/BUSplashAdView.h>

@interface MEBUADAdapter ()<BUNativeExpressAdViewDelegate, BUNativeExpressRewardedVideoAdDelegate, BUSplashAdDelegate, BUNativeExpresInterstitialAdDelegate>
/// 原生模板广告
@property (strong, nonatomic) NSMutableArray<__kindof BUNativeExpressAdView *> *expressAdViews;
/// 原生广告管理类
@property (strong, nonatomic) BUNativeExpressAdManager *nativeExpressAdManager;
/// 激励视频广告管理
@property (nonatomic, strong) BUNativeExpressRewardedVideoAd *rewardedVideoAd;
/// 插屏广告管理
@property (nonatomic, strong) BUNativeExpressInterstitialAd *interstitialAd;

/// 是否需要展示
@property (nonatomic, assign) BOOL needShow;

/// 是否展示误点按钮
@property (nonatomic, assign) BOOL showFunnyBtn;

@end

@implementation MEBUADAdapter

// MARK: - override
+ (instancetype)sharedInstance {
    static MEBUADAdapter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MEBUADAdapter alloc] init];
    });
    return sharedInstance;
}

/// 添加广告参数
- (void)setAdParams:(NSDictionary *)dicParam {
    
}

/// 获取广告平台类型
- (MEAdAgentType)platformType{
    return MEAdAgentTypeBUAD;
}

// MARK: - 开屏广告
- (BOOL)showSplashWithPosid:(NSString *)posid {
    UIViewController *vc = [self topVC];
    if (!vc) {
        return NO;
    }
    
    self.needShow = YES;
    self.posid = posid;
    
    CGRect frame = [UIScreen mainScreen].bounds;
    BUSplashAdView *splashView = [[BUSplashAdView alloc] initWithSlotID:posid frame:frame];
    // tolerateTimeout = CGFLOAT_MAX , The conversion time to milliseconds will be equal to 0
    splashView.tolerateTimeout = 10;
    splashView.delegate = self;
    
    [splashView loadAdData];
    
    [vc.view addSubview:splashView];
    splashView.rootViewController = vc;
    
    return YES;
}

- (void)stopSplashRender {
    self.needShow = NO;
}

// MARK: - 信息流广告
/// 信息流预加载,并存入缓存
/// @param feedWidth 信息流宽度
/// @param posId 广告位id
- (void)saveFeedCacheWithWidth:(CGFloat)feedWidth
                         posId:(NSString *)posId {
    self.needShow = NO;
    self.posid = posId;
    
    BUAdSlot *slot1 = [[BUAdSlot alloc] init];
    slot1.ID = posId;// 广告位id
    slot1.AdType = BUAdSlotAdTypeFeed;
    
    BUSize *imgSize = [BUSize sizeBy:BUProposalSize_Feed228_150];
    slot1.imgSize = imgSize;
    slot1.position = BUAdSlotPositionFeed;
    slot1.isSupportDeepLink = YES;
    
    // self.nativeExpressAdManager可以重用
    if (!self.nativeExpressAdManager) {
       self.nativeExpressAdManager = [[BUNativeExpressAdManager alloc] initWithSlot:slot1 adSize:CGSizeMake(feedWidth, 0)];
    }
    self.nativeExpressAdManager.adslot = slot1;
    self.nativeExpressAdManager.adSize = CGSizeMake(feedWidth, 0);
    self.nativeExpressAdManager.delegate = self;
    [self.nativeExpressAdManager loadAd:1];
}

/// 显示信息流视图
/// @param feedWidth 广告位宽度
/// @param posId 广告位id
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId {
    return [self showFeedViewWithWidth:feedWidth posId:posId withDisplayTime:0];
}

/// 显示信息流视图
/// @param feedWidth 父视图feedWidth
/// @param posId 广告位id
/// @param displayTime 展示时长,0表示不限制时长
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId
              withDisplayTime:(NSTimeInterval)displayTime {
    // 取消所有请求
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showFeedViewTimeout) object:nil];
    self.needShow = YES;
    self.posid = posId;
    
    BUAdSlot *slot1 = [[BUAdSlot alloc] init];
    slot1.ID = posId;// 广告位id
    slot1.AdType = BUAdSlotAdTypeFeed;
    
    BUSize *imgSize = [BUSize sizeBy:BUProposalSize_Feed228_150];
    slot1.imgSize = imgSize;
    slot1.position = BUAdSlotPositionFeed;
    slot1.isSupportDeepLink = YES;
    
    // self.nativeExpressAdManager可以重用
    if (!self.nativeExpressAdManager) {
       self.nativeExpressAdManager = [[BUNativeExpressAdManager alloc] initWithSlot:slot1 adSize:CGSizeMake(feedWidth, 0)];
    }
    self.nativeExpressAdManager.adslot = slot1;
    self.nativeExpressAdManager.adSize = CGSizeMake(feedWidth, 0);
    self.nativeExpressAdManager.delegate = self;
    [self.nativeExpressAdManager loadAd:1];
    
    return YES;
}

/// 移除FeedView
- (void)removeFeedView {
    self.needShow = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showFeedViewTimeout) object:nil];
}

// MARK: - 激励视频
- (BOOL)showRewardVideoWithPosid:(NSString *)posid {
    self.needShow = YES;
    self.posid = posid;
    
    if (![self topVC]) {
        return NO;
    }
    
    if (self.isTheVideoPlaying == YES) {
        // 若当前有视频正在播放,则此次激励视频不播放
        return YES;
    }
    
    if (!self.rewardedVideoAd || !self.rewardedVideoAd.isAdValid) {
        self.needShow = YES;
        BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
        model.userId = @"";
        self.rewardedVideoAd = [[BUNativeExpressRewardedVideoAd alloc] initWithSlotID:posid rewardedVideoModel:model];
        self.rewardedVideoAd.delegate = self;
        [self.rewardedVideoAd loadAdData];
    } else {
        self.needShow = NO;
        [self.rewardedVideoAd showAdFromRootViewController:[self topVC]];
    }
    
    return YES;
}

/// 结束当前视频
- (void)stopCurrentVideo {
    self.needShow = NO;
    if (self.rewardedVideoAd.isAdValid) {
        UIViewController *topVC = [self topVC];
        [topVC dismissViewControllerAnimated:YES completion:nil];
//        self.rewardedVideoAd = nil;
    }
}

// MARK: - 插屏广告
- (BOOL)showInterstitialViewWithPosid:(NSString *)posid showFunnyBtn:(BOOL)showFunnyBtn {
    self.posid = posid;
    self.showFunnyBtn = showFunnyBtn;
    
    if (![self topVC]) {
        return NO;
    }
    
    if (!self.interstitialAd && !self.interstitialAd.isAdValid) {
        self.needShow = YES;
        self.interstitialAd = [[BUNativeExpressInterstitialAd alloc] initWithSlotID:posid imgSize:[BUSize sizeBy:BUProposalSize_Interstitial600_600] adSize:CGSizeMake(300, 300)];
        self.interstitialAd.delegate = self;
        [self.interstitialAd loadAdData];
    } else {
        self.needShow = NO;
        if (self.interstitialAd.isAdValid) {
            [self.interstitialAd showAdFromRootViewController:[self topVC]];
        }
    }
    
    return YES;
}

#pragma mark - BUNativeExpressAdViewDelegate
- (void)nativeExpressAdSuccessToLoad:(BUNativeExpressAdManager *)nativeExpressAd views:(NSArray<__kindof BUNativeExpressAdView *> *)views {
    [self.expressAdViews removeAllObjects];//【重要】不能保存太多view，需要在合适的时机手动释放不用的，否则内存会过大
    
    [self.expressAdViews addObjectsFromArray:views];
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BUNativeExpressAdView *expressView = (BUNativeExpressAdView *)obj;
        expressView.rootViewController = [self topVC];
        [expressView render];
    }];
    
//    if (views.count && self.needShow) {
//        [self.expressAdViews addObjectsFromArray:views];
//        [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            BUNativeExpressAdView *expressView = (BUNativeExpressAdView *)obj;
//            expressView.rootViewController = [self topVC];
//            [expressView render];
//        }];
//    } else if (self.needShow == NO) {
//        // 缓存拉取的广告
//        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetSuccess:feedViews:)]) {
//            [self.feedDelegate adapterFeedCacheGetSuccess:self feedViews:views];
//        }
//    }
    
    DLog(@"【BytedanceUnion】个性化模板拉取广告成功回调");
}

- (void)nativeExpressAdFailToLoad:(BUNativeExpressAdManager *)nativeExpressAd error:(NSError *)error {
    DLog(@"信息流广告加载失败error = %@", error);
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

- (void)nativeExpressAdViewRenderSuccess:(BUNativeExpressAdView *)nativeExpressAdView {
    DLog(@"信息流广告视图渲染完成");
//    if (self.needShow) {
//        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedShowSuccess:feedView:)]) {
//            [self.feedDelegate adapterFeedShowSuccess:self feedView:nativeExpressAdView];
//        }
//    }
    if (self.isGetForCache == YES) {
        // 缓存拉取的广告
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetSuccess:feedViews:)]) {
            [self.feedDelegate adapterFeedCacheGetSuccess:self feedViews:@[nativeExpressAdView]];
        }
    } else {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedShowSuccess:feedView:)]) {
            [self.feedDelegate adapterFeedShowSuccess:self feedView:nativeExpressAdView];
        }
    }
}

- (void)nativeExpressAdViewRenderFail:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
    DLog(@"信息流广告渲染失败");
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
        [self.feedDelegate adapter:self bannerShowFailure:error];
    }
}

- (void)nativeExpressAdViewWillShow:(BUNativeExpressAdView *)nativeExpressAdView {
    DLog(@"%s",__func__);
}

- (void)nativeExpressAdViewDidClick:(BUNativeExpressAdView *)nativeExpressAdView {
    DLog(@"%s",__func__);
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClicked:)]) {
        [self.feedDelegate adapterFeedClicked:self];
    }
}

- (void)nativeExpressAdViewPlayerDidPlayFinish:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
    DLog(@"%s",__func__);
}

- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterWords {
    //【重要】需要在点击叉以后 在这个回调中移除视图，否则，会出现用户点击叉无效的情况
    [self.expressAdViews removeObject:nativeExpressAdView];
    DLog(@"点击广告的x了");
}

- (void)nativeExpressAdViewDidClosed:(BUNativeExpressAdView *)nativeExpressAdView {
//    NSLog(@"%s",__func__);
    DLog(@"关闭广告事件");
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClose:)]) {
        [self.feedDelegate adapterFeedClose:self];
    }
}

- (void)nativeExpressAdViewWillPresentScreen:(BUNativeExpressAdView *)nativeExpressAdView {
//    NSLog(@"%s",__func__);
}


#pragma mark - BUNativeExpressRewardedVideoAdDelegate
- (void)nativeExpressRewardedVideoAdDidLoad:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAd:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
        [self.videoDelegate adapter:self videoShowFailure:error];
    }
}

- (void)nativeExpressRewardedVideoAdDidDownLoadVideo:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdViewRenderSuccess:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.needShow) {
        self.isTheVideoPlaying = YES;
        [self.rewardedVideoAd showAdFromRootViewController:[self topVC]];
    }
}

- (void)nativeExpressRewardedVideoAdViewRenderFail:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd error:(NSError *_Nullable)error {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdWillVisible:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoShowSuccess:)]) {
        [self.videoDelegate adapterVideoShowSuccess:self];
    }
}

- (void)nativeExpressRewardedVideoAdDidVisible:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdWillClose:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClose:)]) {
        [self.videoDelegate adapterVideoClose:self];
    }
    self.isTheVideoPlaying = NO;
    [self.funnyButton removeFromSuperview];
    
    self.needShow = NO;
    [self.rewardedVideoAd loadAdData];
}

- (void)nativeExpressRewardedVideoAdDidClose:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdDidClick:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClicked:)]) {
        [self.videoDelegate adapterVideoClicked:self];
    }
}

- (void)nativeExpressRewardedVideoAdDidClickSkip:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdDidPlayFinish:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    DLog(@"%s",__func__);
    if (error) {
        DLog(@"视频播放失败");
        if (self.isTheVideoPlaying == NO && self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
            [self.videoDelegate adapter:self videoShowFailure:error];
        }
    } else {
        DLog(@"视频播放完毕");
        if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoFinishPlay:)]) {
            [self.videoDelegate adapterVideoFinishPlay:self];
        }
        
        UIViewController *vc = [self topVC];
        if (vc.view.subviews.count && self.showFunnyBtn == YES) {
            UIView *view = vc.view.subviews[0];
            CGRect frame = view.frame;
            CGFloat buttonWidth = 28.f;
            self.funnyButton = [[MEFunnyButton alloc] initWithFrame:CGRectMake(15.f, (iPhoneXSeries ? 40.f : 28.f), buttonWidth, buttonWidth)];
            [[UIApplication sharedApplication].keyWindow addSubview:self.funnyButton];
        }
        
    }
}

- (void)nativeExpressRewardedVideoAdServerRewardDidSucceed:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdServerRewardDidFail:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

-(BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

// MARK: - BUSplashAdDelegate
- (void)splashAdDidClose:(BUSplashAdView *)splashAd {
    [splashAd removeFromSuperview];
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClose:)]) {
        [self.splashDelegate adapterSplashClose:self];
    }
}

- (void)splashAd:(BUSplashAdView *)splashAd didFailWithError:(NSError *)error {
    [splashAd removeFromSuperview];
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapter:splashShowFailure:)]) {
        [self.splashDelegate adapter:self splashShowFailure:error];
    }
}

- (void)splashAdWillVisible:(BUSplashAdView *)splashAd {
    if (self.needShow == NO) {
        [splashAd removeFromSuperview];
    }
    
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashShowSuccess:)]) {
        [self.splashDelegate adapterSplashShowSuccess:self];
    }
}

- (void)splashAdDidClick:(BUSplashAdView *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClicked:)]) {
        [self.splashDelegate adapterSplashClicked:self];
    }
}

- (void)splashAdDidCloseOtherController:(BUSplashAdView *)splashAd interactionType:(BUInteractionType)interactionType {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashDismiss:)]) {
        [self.splashDelegate adapterSplashDismiss:self];
    }
}

//MARK: - BUNativeExpresInterstitialAdDelegate
- (void)nativeExpresInterstitialAdDidLoad:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAd:(BUNativeExpressInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
        [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
    }
}

- (void)nativeExpresInterstitialAdRenderSuccess:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.needShow) {
        [interstitialAd showAdFromRootViewController:[self topVC]];
        if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialLoadSuccess:)]) {
            [self.interstitialDelegate adapterInterstitialLoadSuccess:self];
        }
    }
}

- (void)nativeExpresInterstitialAdRenderFail:(BUNativeExpressInterstitialAd *)interstitialAd error:(NSError *)error {
    DLog(@"error = %@", error);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
        [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
    }
}

- (void)nativeExpresInterstitialAdWillVisible:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    UIViewController *vc = [self topVC];
    if (vc.view.subviews.count && self.showFunnyBtn == YES) {
        UIView *view = vc.view.subviews[0];
        CGRect frame = view.frame;
        CGFloat buttonWidth = 25.f;
        self.funnyButton = [[MEFunnyButton alloc] initWithFrame:CGRectMake(view.frame.size.width-buttonWidth-5.f, 5.f, buttonWidth, buttonWidth)];
        [view addSubview:self.funnyButton];
    }
}

- (void)nativeExpresInterstitialAdDidClick:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialClicked:)]) {
        [self.interstitialDelegate adapterInterstitialClicked:self];
    }
}

- (void)nativeExpresInterstitialAdWillClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialCloseFinished:)]) {
        [self.interstitialDelegate adapterInterstitialCloseFinished:self];
    }
    
    self.needShow = NO;
    [interstitialAd loadAdData];
    [self.funnyButton removeFromSuperview];
}

- (void)nativeExpresInterstitialAdDidClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialCloseFinished:)]) {
        [self.interstitialDelegate adapterInterstitialCloseFinished:self];
    }
    
    self.needShow = NO;
    [interstitialAd loadAdData];
    [self.funnyButton removeFromSuperview];
}

// MARK: - Private
- (void)showFeedViewTimeout {
    self.needShow = NO;
    // 清空所有广告视图
    [self.expressAdViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BUNativeExpressAdView *expressView = (BUNativeExpressAdView *)obj;
        [expressView removeFromSuperview];
        expressView = nil;
    }];
    [self.expressAdViews removeAllObjects];
    
//    NSError *error = [NSError errorWithDomain:@"BUADError" code:0 userInfo:@{NSLocalizedDescriptionKey: @"请求超时"}];
}

@end
