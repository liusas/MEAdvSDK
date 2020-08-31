//
//  MEMobipubAdapter.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/7/14.
//

#import "MEMobipubAdapter.h"
#import "MobiPub.h"
#import "MobiFeedModel.h"

@interface MEMobipubAdapter ()<MobiSplashDelegate, MobiFeedDelegate, MobiRewardedVideoDelegate, MPInterstitialAdControllerDelegate>
/// 是否需要展示
@property (nonatomic, assign) BOOL needShow;

/// 原生模板广告
@property (strong, nonatomic) NSMutableArray *expressAdViews;

@end

@implementation MEMobipubAdapter

// MARK: - override
+ (instancetype)sharedInstance {
    static MEMobipubAdapter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MEMobipubAdapter alloc] init];
    });
    return sharedInstance;
}

+ (void)launchAdPlatformWithAppid:(NSString *)appid {
    
}

- (NSString *)networkName {
    return @"mobisdk";
}

/// 获取广告平台类型
- (MEAdAgentType)platformType{
    return MEAdAgentTypeMobiSDK;
}

// MARK: - 开屏广告
- (void)preloadSplashWithPosid:(NSString *)posid {
    [MobiSplash preloadSplashOrderWithPosid:posid];
}

- (BOOL)loadAndShowSplashWithPosid:(NSString *)posid {
    return [self loadAndShowSplashWithPosid:posid delay:3.0f bottomView:nil];
}

- (BOOL)loadAndShowSplashWithPosid:(NSString *)posid delay:(NSTimeInterval)delay bottomView:(UIView *)view {
    UIViewController *vc = [self topVC];
    if (!vc) {
        return NO;
    }
    
    self.needShow = YES;
    self.posid = posid;
    
    [MobiSplash setDelegate:self forPosid:posid];
    [MobiSplash loadSplashAdAndShowWithWindow:[UIApplication sharedApplication].keyWindow posid:posid SplashModel:nil];
    
    return YES;
}

- (void)stopSplashRenderWithPosid:(NSString *)posid {
    self.needShow = NO;
}

// MARK: - 信息流
/// 显示信息流视图
/// @param feedWidth 广告位宽度
/// @param posId 广告位id
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId
                        count:(NSInteger)count {
    return [self showFeedViewWithWidth:feedWidth posId:posId count:count withDisplayTime:0];
}

/// 显示信息流视图
/// @param feedWidth 父视图feedWidth
/// @param posId 广告位id
/// @param displayTime 展示时长,0表示不限制时长
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId
                        count:(NSInteger)count
              withDisplayTime:(NSTimeInterval)displayTime {
    // 取消所有请求
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showFeedViewTimeout) object:nil];
    self.needShow = YES;
    self.posid = posId;
    
    MobiFeedModel *model = [[MobiFeedModel alloc] init];
    model.feedSize = CGSizeMake(feedWidth, 0);
    model.count = count;
    [MobiFeed loadFeedAdWithPosid:posId feedModel:model];
    [MobiFeed setDelegate:self forPosid:posId];
    
    return YES;
}

/// 移除FeedView
- (void)removeFeedViewWithPosid:(NSString *)posid {
    self.needShow = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showFeedViewTimeout) object:nil];
}

// MARK: - 插屏
- (BOOL)hasInterstitialAvailableWithPosid:(NSString *)posid {
    if (posid == nil) {
        return NO;
    }
    
    MPInterstitialAdController *ad = [MPInterstitialAdController interstitialAdControllerForAdUnitId:posid];
    if (ad) {
        return ad.ready;
    }
    
    return NO;
}
/// 加载插屏页
- (BOOL)loadInterstitialWithPosid:(NSString *)posid {
    self.posid = posid;
    
    if (![self topVC]) {
        return NO;
    }
    
    self.needShow = YES;
    MPInterstitialAdController *ad = [MPInterstitialAdController interstitialAdControllerForAdUnitId:posid];
    
    ad.delegate = self;
    [ad loadAd];
    
    return YES;
}

/// 展示插屏页
- (void)showInterstitialFromViewController:(UIViewController *)rootVC posid:(NSString *)posid {
    // 这里初始化没关系,内部会先从已经存在的实例中拿出对应实例的
    MPInterstitialAdController *ad = [MPInterstitialAdController interstitialAdControllerForAdUnitId:posid];
    if (ad.ready == YES) {
        [ad showFromViewController:[self topVC]];
    }
}

- (void)stopInterstitialWithPosid:(NSString *)posid {
    self.needShow = NO;
}

// MARK: - 激励视频
/// 是否有有效的激励视频
- (BOOL)hasRewardedVideoAvailableWithPosid:(NSString *)posid {
    if (posid == nil) {
        return NO;
    }
    
    return [MobiRewardedVideo hasAdAvailableForPosid:posid];
}

/// 加载激励视频
- (BOOL)loadRewardVideoWithPosid:(NSString *)posid {
    self.needShow = YES;
    self.posid = posid;
    
    if (![self topVC]) {
        return NO;
    }
    
    [MobiRewardedVideo loadRewardedVideoAdWithPosid:posid rewardedVideoModel:nil];
    [MobiRewardedVideo setDelegate:self forPosid:posid];
    
    return YES;
}

/// 展示激励视频
- (void)showRewardedVideoFromViewController:(UIViewController *)rootVC posid:(NSString *)posid {
    if (posid == nil) {
        return;
    }
    
    if (self.isTheVideoPlaying == NO && [MobiRewardedVideo hasAdAvailableForPosid:posid]) {
        self.isTheVideoPlaying = YES;
        [MobiRewardedVideo showRewardedVideoAdForPosid:posid fromViewController:rootVC withReward:nil];
    }
}

/// 结束当前视频
- (void)stopCurrentVideoWithPosid:(NSString *)posid {
    self.needShow = NO;
    if ([MobiRewardedVideo hasAdAvailableForPosid:posid]) {
        UIViewController *topVC = [self topVC];
        [topVC dismissViewControllerAnimated:YES completion:nil];
    }
}

// MARK: - 全屏视频广告
/// 全屏视频是否有效
- (BOOL)hasFullscreenVideoAvailableWithPosid:(NSString *)posid {return NO;}
/// 加载全屏视频
- (BOOL)loadFullscreenWithPosid:(NSString *)posid {return NO;}
/// 展示全屏视频
- (void)showFullscreenVideoFromViewController:(UIViewController *)rootVC posid:(NSString *)posid {}
/// 关闭当前视频
- (void)stopFullscreenVideoWithPosid:(NSString *)posid {}

// MARK: - MobiSplashDelegate
/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreen:(MobiSplash *)splashAd {
    if (self.needShow == NO) {
//        [splashAd removeFromSuperview];
    }
    
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashShowSuccess:)]) {
        [self.splashDelegate adapterSplashShowSuccess:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Show;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoad:(MobiSplash *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashLoadSuccess:)]) {
        [self.splashDelegate adapterSplashLoadSuccess:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresent:(MobiSplash *)splashAd withError:(NSError *)error {
    splashAd = nil;
    if (self.needShow) {
        if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapter:splashShowFailure:)]) {
            [self.splashDelegate adapter:self splashShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackground:(MobiSplash *)splashAd {
    
}

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposured:(MobiSplash *)splashAd {
    
}

/**
 *  开屏广告点击回调
 */
- (void)splashAdClicked:(MobiSplash *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClicked:)]) {
        [self.splashDelegate adapterSplashClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosed:(MobiSplash *)splashAd {
//    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClose:)]) {
//        [self.splashDelegate adapterSplashClose:self];
//    }
    splashAd = nil;
}

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosed:(MobiSplash *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClose:)]) {
        [self.splashDelegate adapterSplashClose:self];
    }
    splashAd = nil;
}

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpire:(MobiSplash *)splashAd {
    NSError *error = [NSError errorWithDomain:@"ad has expired" code:10010 userInfo:nil];
    [self splashAdFailToPresent:splashAd withError:error];
}

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModal:(MobiSplash *)splashAd {
    
}

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModal:(MobiSplash *)splashAd {
    
}

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModal:(MobiSplash *)splashAd {
    
}

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModal:(MobiSplash *)splashAd {
    
}

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAd:(MobiSplash *)splashAd lifeTime:(NSUInteger)time {
    
}

// MARK: - MobiFeedDelegate
- (void)nativeExpressAdSuccessToLoad:(MobiFeed *)nativeExpressAd views:(NSArray<__kindof MobiNativeExpressFeedView *> *)views {
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 上报日志
        MEAdLogModel *model = [MEAdLogModel new];
        model.event = AdLogEventType_Load;
        model.st_t = AdLogAdType_Feed;
        model.so_t = self.sortType;
        model.posid = self.sceneId;
        model.network = self.networkName;
        model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
        // 先保存到数据库
        [MEAdLogModel saveLogModelToRealm:model];
        // 立即上传
        [MEAdLogModel uploadImmediately];
    }];
    
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedLoadSuccess:feedViews:)]) {
        [self.feedDelegate adapterFeedLoadSuccess:self feedViews:views];
    }
}

- (void)nativeExpressAdFailToLoad:(MobiFeed *)nativeExpressAd error:(NSError *)error {
    if (self.isGetForCache == YES) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetFailed:)]) {
            [self.feedDelegate adapterFeedCacheGetFailed:error];
        }
        return;
    }
    
    if (self.needShow) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
            [self.feedDelegate adapter:self bannerShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Feed;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressAdViewRenderSuccess:(MobiNativeExpressFeedView *)nativeExpressAdView {
    if (self.isGetForCache == YES) {
        // 缓存拉取的广告
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetSuccess:feedViews:)]) {
            [self.feedDelegate adapterFeedCacheGetSuccess:self feedViews:@[nativeExpressAdView]];
        }
    } else {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedShowSuccess:feedView:)]) {
            [self.feedDelegate adapterFeedShowSuccess:self feedView:nativeExpressAdView];
        }
        
        // 上报日志
        MEAdLogModel *model = [MEAdLogModel new];
        model.event = AdLogEventType_Show;
        model.st_t = AdLogAdType_Feed;
        model.so_t = self.sortType;
        model.posid = self.sceneId;
        model.network = self.networkName;
        model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
        // 先保存到数据库
        [MEAdLogModel saveLogModelToRealm:model];
        // 立即上传
        [MEAdLogModel uploadImmediately];
    }
}

- (void)nativeExpressAdViewRenderFail:(MobiNativeExpressFeedView *)nativeExpressAdView {
    NSError *error = [NSError errorWithDomain:@"mobipub render error" code:-1011 userInfo:nil];
    
    if (self.needShow) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
            [self.feedDelegate adapter:self bannerShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Feed;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Render;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressAdViewClicked:(MobiNativeExpressFeedView *)nativeExpressAdView {
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClicked:)]) {
        [self.feedDelegate adapterFeedClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_Feed;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

// MARK: - MobiRewardedVideoDelegate
/**
 * 激励视频资源加载完成回调此方法
 *
 */
- (void)rewardedVideoAdDidLoad:(MobiRewardedVideo *)rewardedVideo {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoLoadSuccess:)]) {
        [self.videoDelegate adapterVideoLoadSuccess:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 * 广告资源缓存成功调用此方法
 * 建议在此方法回调后执行播放视频操作
 */
- (void)rewardedVideoAdVideoDidLoad:(MobiRewardedVideo *)rewardedVideo {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoDidDownload:)]) {
        [self.videoDelegate adapterVideoDidDownload:self];
    }
}

/**
 * 激励视频资源加载失败回调此方法
 * @param error NSError类型的错误信息
 */
- (void)rewardedVideoAdDidFailToLoad:(MobiRewardedVideo *)rewardedVideo error:(NSError *)error {
    if (self.needShow) {
        self.isTheVideoPlaying = NO;
        if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
            [self.videoDelegate adapter:self videoShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 * 当一个posid加载完的激励视频资源失效时(过期),回调此方法
 * 这也是为什么需要在调用`showRewardedVideoAdForPosid`之前调用`hasAdAvailableForPosid`判断一下广告资源是否有效
 */
- (void)rewardedVideoAdDidExpire:(MobiRewardedVideo *)rewardedVideo {
    NSError *error = [NSError errorWithDomain:@"mobipub rewarded video was expired" code:-1012 userInfo:nil];
    if (self.needShow) {
        self.isTheVideoPlaying = NO;
        if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
            [self.videoDelegate adapter:self videoShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 * 当试图播放激励视频资源时出现错误时,调用此方法
 * @param error NSError类型的错误信息,提示为什么播放错误
 */
- (void)rewardedVideoAdDidFailToPlay:(MobiRewardedVideo *)rewardedVideo error:(NSError *)error {
    if (self.needShow) {
        self.isTheVideoPlaying = NO;
        if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
            [self.videoDelegate adapter:self videoShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Render;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 * 当激励视频广告即将显示时,调用此方法
 *
 */
- (void)rewardedVideoAdWillAppear:(MobiRewardedVideo *)rewardedVideo {
    self.isTheVideoPlaying = YES;
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoShowSuccess:)]) {
        [self.videoDelegate adapterVideoShowSuccess:self];
    }
}

/**
 * 当激励视频广告已经显示时,调用此方法
 *
 */
- (void)rewardedVideoAdDidAppear:(MobiRewardedVideo *)rewardedVideo {
    
}

/**
 * 当激励视频广告即将关闭时,调用此方法
 *
 */
- (void)rewardedVideoAdWillDisappear:(MobiRewardedVideo *)rewardedVideo {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClose:)]) {
        [self.videoDelegate adapterVideoClose:self];
    }
    self.isTheVideoPlaying = NO;
    
    self.needShow = NO;
    [MobiRewardedVideo loadRewardedVideoAdWithPosid:self.posid rewardedVideoModel:nil];
}

/**
 * 当激励视频广告已经关闭时,调用此方法
 *
 */
- (void)rewardedVideoAdDidDisappear:(MobiRewardedVideo *)rewardedVideo {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClose:)]) {
        [self.videoDelegate adapterVideoClose:self];
    }
}

/**
 * 当用户点击了激励视频广告时,回调此方法
 *
 */
- (void)rewardedVideoAdDidReceiveTapEvent:(MobiRewardedVideo *)rewardedVideo {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClicked:)]) {
        [self.videoDelegate adapterVideoClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 * 当激励视频即将引发用户离开应用时,调用此方法
 *
 */
- (void)rewardedVideoAdWillLeaveApplication:(MobiRewardedVideo *)rewardedVideo {
    
}

/**
 * 当激励视频播放到已经满足奖励条件时,会回调此方法,我们可以依次给予用户奖励
 *
 * @param reward 返回给用户的奖励信息
 */
- (void)rewardedVideoAdShouldReward:(MobiRewardedVideo *)rewardedVideo reward:(MobiRewardedVideoReward *)reward {
    
}

// MARK: - MPInterstitialAdControllerDelegate
- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialLoadSuccess:)]) {
        [self.interstitialDelegate adapterInterstitialLoadSuccess:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_Interstitial;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial {
    NSError *error = [NSError errorWithDomain:@"mobipub interstitial error" code:-1011 userInfo:nil];
    if (self.needShow) {
        if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
            [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
        }
    }
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Interstitial;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial
                          withError:(NSError *)error {
    if (self.needShow) {
        if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
            [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
        }
    }
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Interstitial;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial {
    if (self.needShow) {
        if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialShowSuccess:)]) {
            [self.interstitialDelegate adapterInterstitialShowSuccess:self];
        }
    }
}


- (void)interstitialDidAppear:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialCloseFinished:)]) {
        [self.interstitialDelegate adapterInterstitialCloseFinished:self];
    }
    
    self.needShow = NO;
    [interstitial loadAd];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial {
    
}

/**
 * Call this method when the interstitial ad will Present SKStoreProductViewController
 */
- (void)interstitialWillPresentModal:(MPInterstitialAdController *)interstitial {
    
}
/**
* Call this method when the interstitial ad dismiss SKStoreProductViewController
*/
- (void)interstitialDidDismissModal:(MPInterstitialAdController *)interstitial {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialDismiss:)]) {
        [self.interstitialDelegate adapterInterstitialDismiss:self];
    }
}

- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialClicked:)]) {
        [self.interstitialDelegate adapterInterstitialClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

@end
