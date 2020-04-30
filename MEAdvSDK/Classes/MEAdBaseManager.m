//
//  MEAdBaseManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//  所有广告平台的管理

#import "MEAdBaseManager.h"
#import <BUAdSDK/BUAdSDKManager.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <KSAdSDK/KSAdSDK.h>
#import "MEBaseAdapter.h"

#import "MESplashAdManager.h"
#import "MEFeedAdManager.h"
#import "MERewardedVideoManager.h"
#import "MEInterstitialAdManager.h"

#import "MEAdLogModel.h"

static  MEAdBaseManager *baseManager;
static dispatch_once_t onceToken;

@interface MEAdBaseManager ()

@property (nonatomic, weak) id target;
@property (nonatomic, strong) MESplashAdManager *splashAdManager;
@property (nonatomic, strong) MEFeedAdManager *feedAdManager;
@property (nonatomic, strong) MERewardedVideoManager *rewardedVideoManager;
@property (nonatomic, strong) MEInterstitialAdManager *interstitialManager;
/// 配置请求成功和广告平台初始化成功的block
@property (nonatomic, copy) RequestAndInitFinished requestConfigFinished;
/// 广告平台是否已经初始化
@property (nonatomic, assign) BOOL isPlatformInit;
@end

@implementation MEAdBaseManager

// MARK: - Public

+ (instancetype)sharedInstance {
    dispatch_once(&onceToken, ^{
        baseManager = [[MEAdBaseManager alloc] init];
    });
    return baseManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

/// 从服务端请求广告平台配置信息
/// @param adRequestUrl 服务端的请求baseUrl
/// @param logUrl 日志上报url
- (void)requestPlatformConfigWithUrl:(NSString *)adRequestUrl
                              logUrl:(NSString *)logUrl
                            deviceId:(NSString *)deviceId
                            finished:(RequestAndInitFinished)finished {
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listenConfigAndInitSuccess:) name:kRequestConfigNotify object:nil];
    self.requestConfigFinished = finished;
    [[MEConfigManager sharedInstance] platformConfigIfRequestWithUrl:adRequestUrl];
    [MEConfigManager sharedInstance].adLogUrl = logUrl;
    [MEConfigManager sharedInstance].deviceId = deviceId;
}



/// 初始化广告平台
/// @param BUADAppId 穿山甲Appid
/// @param GDTAppId 广点通Appid
+ (void)lanuchAdPlatformWithBUADAppId:(NSString *)BUADAppId
                             GDTAppId:(NSString *)GDTAppId
                              KSAppId:(NSString *)ksAppid {
    // 穿山甲初始化
    [BUAdSDKManager setAppID:BUADAppId];
#if DEBUG
    // Whether to open log. default is none.
    [BUAdSDKManager setLoglevel:BUAdSDKLogLevelDebug];
#endif
    [BUAdSDKManager setIsPaidApp:NO];
    
    // 快手初始化
    [KSAdSDKManager setAppId:ksAppid];
    // 根据需要设置⽇志级别
    [KSAdSDKManager setLoglevel:KSAdSDKLogLevelOff];
    
    // 初始化谷歌SDK
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
    
    [MEAdBaseManager sharedInstance].isPlatformInit = YES;
    // 配置穿山甲和广点通id
    [MEConfigManager sharedInstance].BUADAPPId = BUADAppId;
    [MEConfigManager sharedInstance].GDTAPPId = GDTAppId;
    
    if ([MEAdBaseManager sharedInstance].requestConfigFinished) {
        [MEAdBaseManager sharedInstance].requestConfigFinished(YES);
    }
}

/// 初始化广告平台成功的回调
- (void)listenConfigAndInitSuccess:(NSNotification *)notify {
    BOOL success = [notify object];
    if (self.requestConfigFinished) {
        self.requestConfigFinished(success);
    }
}

// MARK: 开屏广告
/// 展示开屏广告
- (void)showSplashAdvTarget:(id)target sceneId:(NSString *)sceneId {
    _target = target;
    
    if (target == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    self.splashDelegate = target;
    
    self.splashAdManager = [MESplashAdManager shareInstance];
    
    [self.splashAdManager showSplashAdvWithSceneId:sceneId Finished:^{
        [weakSelf splashFinishedOperation];
    } failed:^(NSError * _Nonnull error) {
        [weakSelf splashFailedOpertion:error];
    }];
}

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender {
    [self.splashAdManager stopSplashRender];
}

// MARK: 插屏广告
/// 展示插屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param showFunnyBtn 是否展示误点按钮
- (void)showInterstitialAdvWithTarget:(id)target
                              sceneId:(NSString *)sceneId
                         showFunnyBtn:(BOOL)showFunnyBtn {
    _target = target;
    
    if (target == nil) {
        // 需要根据target给予action和响应
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    self.interstitialDelegate = target;
    
    self.interstitialManager = [MEInterstitialAdManager shareInstance];
    
    [self.interstitialManager showInterstitialAdvWithSceneId:sceneId showFunnyBtn:showFunnyBtn Finished:^{
        [weakSelf interstitialFinishedOperation];
    } failed:^(NSError * _Nonnull error) {
        [weakSelf interstitialFailedOpertion:error];
    }];
}

// MARK: 信息流广告
/// 缓存信息流广告
/// @param feedModelArr MEAdFeedModel实例的数组,包含信息流宽度和场景id
- (void)saveFeedAdvToCacheWithFeedModelArr:(NSArray <MEAdFeedModel *>*)feedModelArr {
    if ([MEConfigManager sharedInstance].isInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    [feedModelArr enumerateObjectsUsingBlock:^(MEAdFeedModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            MEAdFeedModel *model = obj;
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            self.feedAdManager = [MEFeedAdManager shareInstance];
            [self.feedAdManager saveFeedCacheWithWidth:model.width sceneId:model.sceneId finished:^{
                dispatch_semaphore_signal(semaphore);
            } failed:^(NSError * _Nonnull error) {
                dispatch_semaphore_signal(semaphore);
            }];
        });
    }];
}

/**
*  展示信息流广告
*  @param bgWidth 必填,信息流背景视图的宽度
*  @param sceneId 场景Id,在MEAdBaseManager.h中可查
*  @param target 必填,用来承接代理
*/
- (void)showFeedAdvWithBgWidth:(CGFloat)bgWidth sceneId:(NSString *)sceneId Target:(id)target {
    _target = target;
    
    if ([MEConfigManager sharedInstance].isInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    if (target == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    self.feedAdManager = [MEFeedAdManager shareInstance];
//    self.feedAdManager = [[MEFeedAdManager alloc] init];
    [self.feedAdManager showFeedViewWithWidth:bgWidth sceneId:sceneId finished:^(UIView * _Nonnull feedView) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.feedDelegate = target;
        [strongSelf feedViewFinishedOperation:feedView];
    } failed:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.feedDelegate = target;
        [strongSelf feedViewFailedOpertion:error];
    }];
}

/// 缓存自渲染信息流广告
/// @param feedModelArr MEAdFeedModel实例的数组,包含信息流宽度和场景id
- (void)saveRenderFeedAdvToCacheWithFeedModelArr:(NSArray <MEAdFeedModel *>*)feedModelArr {
    if ([MEConfigManager sharedInstance].isInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    [feedModelArr enumerateObjectsUsingBlock:^(MEAdFeedModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            MEAdFeedModel *model = obj;
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            self.feedAdManager = [MEFeedAdManager shareInstance];
            [self.feedAdManager saveRenderFeedCacheWithSceneId:model.sceneId finished:^(UIView * _Nonnull feedView) {
                dispatch_semaphore_signal(semaphore);
            } failed:^(NSError * _Nonnull error) {
                dispatch_semaphore_signal(semaphore);
            }];
        });
    }];
}

/// 展示自渲染信息流广告
/// @param sceneId 场景id
/// @param target  必填,用来承接代理
- (void)showRenderFeedAdvWithSceneId:(NSString *)sceneId Target:(id)target {
    _target = target;
    
    if ([MEConfigManager sharedInstance].isInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    if (target == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    self.feedDelegate = target;
    self.feedAdManager = [MEFeedAdManager shareInstance];
    [self.feedAdManager showRenderFeedViewWithSceneId:sceneId finished:^(UIView * _Nonnull feedView) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.feedDelegate = target;
        [strongSelf feedViewFinishedOperation:feedView];
    } failed:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.feedDelegate = target;
        [strongSelf feedViewFailedOpertion:error];
    }];
}

// MARK: 激励视频广告
/**
 *  展示激励视频广告
 *  @param sceneId 场景Id,在MEAdBaseManager.h中可查
 *  sceneId有以下可选项
 *  2048001 金币泡泡翻倍激励视频
 *  2048005 签到翻倍激励视频
 *  2048006 观看激励视频任务
 *  2048008 大转盘激励视频
 *  2048011 大转盘金币奖励翻倍激励视频
 *  2048019 提现页激励视频
 *  2048020 fault激励视频
 *  @param target 必填,接收回调
*/
- (void)showRewardedVideoWithSceneId:(NSString *)sceneId target:(id)target {
    if (target == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    if ([MEConfigManager sharedInstance].isInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.rewardVideoDelegate = target;
    self.rewardedVideoManager = [MERewardedVideoManager shareInstance];
    [self.rewardedVideoManager showRewardVideoWithSceneId:sceneId Finished:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf rewardVideoShowSuccessOperation];
    } failed:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf rewardVideoFailedOpertion:error];
    }];
}

/// 停止当前播放的视频
- (void)stopRewardedVideo {
    [self.rewardedVideoManager stopCurrentVideo];
}

// MARK: - 信息流广告回调
/// 信息流广告展示成功后的操作
- (void)feedViewFinishedOperation:(UIView *)feedView {
    self.currentAdPlatform = self.feedAdManager.currentAdPlatform;
    
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(feedViewShowSuccess:feedView:)]) {
        [self.feedDelegate feedViewShowSuccess:self feedView:feedView];
    }
    
    // 点击广告监听
    self.feedAdManager.clickBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.feedDelegate && [strongSelf.feedDelegate respondsToSelector:@selector(feedViewClicked:)]) {
            [strongSelf.feedDelegate feedViewClicked:strongSelf];
        }
    };
    
    // 关闭广告的监听
    self.feedAdManager.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.feedDelegate && [strongSelf.feedDelegate respondsToSelector:@selector(feedViewCloseClick:)]) {
            [strongSelf.feedDelegate feedViewCloseClick:strongSelf];
        }
    };
}

/// 信息流广告展示失败的操作
- (void)feedViewFailedOpertion:(NSError *)error {
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(feedView:showFeedViewFailure:)]) {
        [self.feedDelegate feedViewShowFeedViewFailure:error];
    }
}

// MARK: - 激励视频广告回调
- (void)rewardVideoShowSuccessOperation {
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.rewardVideoDelegate && [self.rewardVideoDelegate respondsToSelector:@selector(rewardVideoShowSuccess:)]) {
        [self.rewardVideoDelegate rewardVideoShowSuccess:self];
    }
    
    // 视频播放完毕
    self.rewardedVideoManager.finishPlayBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.rewardVideoDelegate && [strongSelf.rewardVideoDelegate respondsToSelector:@selector(rewardVideoFinishPlay:)]) {
            [strongSelf.rewardVideoDelegate rewardVideoFinishPlay:strongSelf];
        }
    };
    
    // 点击广告监听
    self.rewardedVideoManager.clickBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.rewardVideoDelegate && [strongSelf.rewardVideoDelegate respondsToSelector:@selector(rewardVideoClicked:)]) {
            [strongSelf.rewardVideoDelegate rewardVideoClicked:strongSelf];
        }
    };
    
    // 关闭广告的监听
    self.rewardedVideoManager.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.rewardVideoDelegate && [strongSelf.rewardVideoDelegate respondsToSelector:@selector(rewardVideoClose:)]) {
            [strongSelf.rewardVideoDelegate rewardVideoClose:strongSelf];
        }
    };
}

/// 激励视频广告展示失败的操作
- (void)rewardVideoFailedOpertion:(NSError *)error {
    if (self.rewardVideoDelegate && [self.rewardVideoDelegate respondsToSelector:@selector(rewardVideoShowFailure:)]) {
        [self.rewardVideoDelegate rewardVideoShowFailure:error];
    }
}

// MARK: - 开屏广告回调
/// 开屏广告展示成功后的操作
- (void)splashFinishedOperation {
    self.currentAdPlatform = self.splashAdManager.currentAdPlatform;
    
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(splashShowSuccess:)]) {
        [self.splashDelegate splashShowSuccess:self];
    }
    
    // 点击广告监听
    self.splashAdManager.clickBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.splashDelegate && [strongSelf.splashDelegate respondsToSelector:@selector(splashClicked:)]) {
            [strongSelf.splashDelegate splashClicked:strongSelf];
        }
    };
    
    // 关闭广告的监听
    self.splashAdManager.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.splashDelegate && [strongSelf.splashDelegate respondsToSelector:@selector(splashClosed:)]) {
            [strongSelf.splashDelegate splashClosed:strongSelf];
        }
    };
    
    self.splashAdManager.clickThenDismiss = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.splashDelegate && [strongSelf.splashDelegate respondsToSelector:@selector(splashDismiss:)]) {
            [strongSelf.splashDelegate splashDismiss:strongSelf];
        }
    };
}

/// 信息流广告展示失败的操作
- (void)splashFailedOpertion:(NSError *)error {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(feedView:showFeedViewFailure:)]) {
        [self.splashDelegate splashShowFailure:error];
    }
}

// MARK: - 插屏广告回调
/// 广告展示成功后的操作
- (void)interstitialFinishedOperation {
    self.currentAdPlatform = self.interstitialManager.currentAdPlatform;
    
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(interstitialShowSuccess:)]) {
        [self.interstitialDelegate interstitialShowSuccess:self];
    }
    
    // 点击广告监听
    self.interstitialManager.clickBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.interstitialDelegate && [strongSelf.interstitialDelegate respondsToSelector:@selector(interstitialClicked:)]) {
            [strongSelf.interstitialDelegate interstitialClicked:strongSelf];
        }
    };
    
    // 关闭广告的监听
    self.interstitialManager.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.interstitialDelegate && [strongSelf.interstitialDelegate respondsToSelector:@selector(interstitialClosed:)]) {
            [strongSelf.interstitialDelegate interstitialClosed:strongSelf];
        }
    };
    
    self.interstitialManager.clickThenDismiss = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.interstitialDelegate && [strongSelf.interstitialDelegate respondsToSelector:@selector(interstitialDismiss:)]) {
            [strongSelf.interstitialDelegate interstitialDismiss:strongSelf];
        }
    };
}

/// 广告展示失败的操作
- (void)interstitialFailedOpertion:(NSError *)error {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(interstitialShowFailure:)]) {
        [self.interstitialDelegate interstitialShowFailure:error];
    }
}

@end
