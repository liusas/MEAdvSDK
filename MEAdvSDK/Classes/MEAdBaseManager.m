//
//  MEAdBaseManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//  所有广告平台的管理

#import "MEAdBaseManager.h"

#import "MESplashAdManager.h"
#import "MEFeedAdManager.h"
#import "MERewardedVideoManager.h"
#import "MEInterstitialAdManager.h"
#import "MEFullscreenManager.h"
#import <Realm.h>

static  MEAdBaseManager *baseManager;
static dispatch_once_t onceToken;

@interface MEAdBaseManager ()

@property (nonatomic, weak) id target;
@property (nonatomic, strong) MESplashAdManager *splashAdManager;
@property (nonatomic, strong) MEFeedAdManager *feedAdManager;


@property (nonatomic, strong) MERewardedVideoManager *rewardedVideoManager;
//存放rewardedManager的字典
@property (nonatomic, strong) NSMutableDictionary *rewardedVideoManagers;

@property (nonatomic, strong) MEFullscreenManager *fullscreenManager;
//存放fullscreenManager的字典
@property (nonatomic, strong) NSMutableDictionary *fullscreenManagers;

@property (nonatomic, strong) MEInterstitialAdManager *interstitialManager;
// 存放interstitialManager的字典
@property (nonatomic, strong) NSMutableDictionary *interstitialManagers;

/// 配置请求成功和广告平台初始化成功的block
@property (nonatomic, copy) RequestAndInitFinished requestConfigFinished;
/// 广告平台是否已经初始化
@property (nonatomic, assign) BOOL isPlatformInit;
@end

@implementation MEAdBaseManager

// MARK: - Public
// 单例初始化
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

+ (void)launchWithAppID:(NSString *)appid {
    [self launchWithAppID:appid finished:nil];
    
    // Override point for customization after application launch.
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    // 设置新的架构版本。这个版本号必须高于之前所用的版本号（如果您之前从未设置过架构版本，那么这个版本号设置为 0）
    config.schemaVersion = 0;
    // 设置闭包，这个闭包将会在打开低于上面所设置版本号的 Realm 数据库的时候被自动调用
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        // 目前我们还未进行数据迁移，因此 oldSchemaVersion == 0
        if (oldSchemaVersion < 1) {
            // 什么都不要做！Realm 会自行检测新增和需要移除的属性，然后自动更新硬盘上的数据库架构
        }
    };
    // 告诉 Realm 为默认的 Realm 数据库使用这个新的配置对象
    [RLMRealmConfiguration setDefaultConfiguration:config];
    // 现在我们已经告诉了 Realm 如何处理架构的变化，打开文件之后将会自动执行迁移
    [RLMRealm defaultRealm];
}

+ (void)launchWithAppID:(NSString *)appid finished:(RequestAndInitFinished)finished {
    [MEConfigManager loadWithAppID:appid finished:^{
        MEAdBaseManager *sharedInstance = [MEAdBaseManager sharedInstance];
        sharedInstance.isPlatformInit = YES;
        
        if (finished) {
            finished(YES);
        }
    }];
}

// MARK: 开屏广告
- (void)preloadSplashWithSceneId:(NSString *)sceneId delegate:(id)delegate {
    _target = delegate;
    
    if (delegate == nil) {
        // 需要根据delegate给予action和响应
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    self.splashDelegate = delegate;
    
    //    self.splashAdManager = [MESplashAdManager shareInstance];
    self.splashAdManager = [[MESplashAdManager alloc] init];
    
    [self.splashAdManager preloadSplashWithSceneId:sceneId Finished:^{
        // 加载成功
        [weakSelf splashFinishedOperation];
    } failed:^(NSError *error) {
        // 加载失败
        [weakSelf splashFailedOpertion:error];
    }];
}

- (void)loadAndShowSplashAdSceneId:(NSString *)sceneId delegate:(id)delegate delay:(NSTimeInterval)delay bottomView:(UIView *)bottomView {
    _target = delegate;
    
    if (delegate == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    self.splashDelegate = delegate;
    
    //    self.splashAdManager = [MESplashAdManager shareInstance];
    self.splashAdManager = [[MESplashAdManager alloc] init];
    
    [self.splashAdManager loadSplashAdWithSceneId:sceneId delay:delay Finished:^{
        [weakSelf splashFinishedOperation];
    } failed:^(NSError *error) {
        [weakSelf splashFailedOpertion:error];
    }];
}

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender:(NSString *)sceneId {
    [self.splashAdManager stopSplashRender:sceneId];
}

// MARK: 插屏广告
- (void)loadInterstitialWithSceneId:(NSString *)sceneId delegate:(id)delegate {
    _target = delegate;
    
    if (delegate == nil) {
        // 需要根据target给予action和响应
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    self.interstitialDelegate = delegate;
    
    //    self.interstitialManager = [MEInterstitialAdManager shareInstance];
    self.interstitialManager = [[MEInterstitialAdManager alloc] init];
    self.interstitialManagers[sceneId] = self.interstitialManager;
    [self.interstitialManager loadInterstitialWithSceneId:sceneId finished:^{
        [weakSelf interstitialFinishedOperation];
    } failed:^(NSError * _Nonnull error) {
        [weakSelf interstitialFailedOpertion:error];
    }];
}

- (void)showInterstitialFromViewController:(UIViewController *)rootVC sceneId:(NSString *)sceneId {
    self.interstitialDelegate = rootVC;
    MEInterstitialAdManager *adManager = self.interstitialManagers[sceneId];

    if (adManager) {
        [adManager showInterstitialFromViewController:rootVC sceneId:sceneId];
        return;
    }
    
    // 没有合适的 adManager 表示当前没有广告可展示
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(interstitialShowFailure:)]) {
        NSError *error = [NSError errorWithDomain:@"no ads to show" code:0 userInfo:nil];
        [self.interstitialDelegate interstitialShowFailure:error];
    }
}

- (void)stopInterstitialRender:(NSString *)sceneId {
    if (sceneId == nil) {
        return;
    }
    
    MEInterstitialAdManager *adManager = self.interstitialManagers[sceneId];

    if (adManager) {
        [adManager stopInterstitialRenderWithSceneId:sceneId];
        return;
    }
}

- (BOOL)hasInterstitialAvailableWithSceneId:(NSString *)sceneId {
    if (sceneId == nil) {
        return NO;
    }
    
    MEInterstitialAdManager *adManager = self.interstitialManagers[sceneId];

    if (adManager) {
        return [adManager hasInterstitialAvailableWithSceneId:sceneId];
    }
    
    return NO;
}

// MARK: 激励视频广告
- (void)loadRewardedVideoWitSceneId:(NSString *)sceneId delegate:(id)delegate {
    if (delegate == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    if (self.isPlatformInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.rewardVideoDelegate = delegate;
    //    self.rewardedVideoManager = [MERewardedVideoManager shareInstance];
    self.rewardedVideoManager = [[MERewardedVideoManager alloc] init];
    self.rewardedVideoManagers[sceneId] = self.rewardedVideoManager;
    [self.rewardedVideoManager loadRewardedVideoWithSceneId:sceneId finished:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf rewardVideoShowSuccessOperation];
    } failed:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf rewardVideoFailedOpertion:error];
    }];
}

- (void)showRewardedVideoFromViewController:(UIViewController *)rootVC sceneId:(NSString *)sceneId {
    self.rewardVideoDelegate = rootVC;
    MERewardedVideoManager *adManager = self.rewardedVideoManagers[sceneId];

    if (adManager) {
        [adManager showRewardedVideoFromViewController:rootVC sceneId:sceneId];
        return;
    }
    
    // 没有合适的 adManager 表示当前没有广告可展示
    if (self.rewardVideoDelegate && [self.rewardVideoDelegate respondsToSelector:@selector(rewardVideoShowFailure:)]) {
        NSError *error = [NSError errorWithDomain:@"no ads to show" code:0 userInfo:nil];
        [self.rewardVideoDelegate rewardVideoShowFailure:error];
    }
}

/// 停止当前播放的视频
- (void)stopRewardedVideo:(NSString *)sceneId {
    if (sceneId == nil) {
        return;
    }
    MERewardedVideoManager *adManager = self.rewardedVideoManagers[sceneId];

    if (adManager) {
        [adManager stopCurrentVideoWithSceneId:sceneId];
        return;
    }
}

- (BOOL)hasRewardedVideoAvailableWithSceneId:(NSString *)sceneId {
    if (sceneId == nil) {
        return NO;
    }
    
    MERewardedVideoManager *adManager = self.rewardedVideoManagers[sceneId];

    if (adManager) {
        return [adManager hasRewardedVideoAvailableWithSceneId:sceneId];
    }
    
    return NO;
}

// MARK: - 全屏视频
/// 加载全屏视频广告
/// @param sceneId 广告位 id
/// @param delegate 必填,用来接收代理
- (void)loadFullscreenVideoWithSceneId:(NSString *)sceneId delegate:(id)delegate {
    if (delegate == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    if (self.isPlatformInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.fullscreenVideoDelegate = delegate;
    self.fullscreenManager = [[MEFullscreenManager alloc] init];
    self.fullscreenManagers[sceneId] = self.fullscreenManager;
    [self.fullscreenManager loadFullscreenVideoWithSceneId:sceneId finished:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf fullscreenVideoShowSuccessOperation];
    } failed:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf fullscreenVideoFailedOpertion:error];
    }];
}
/// 展示全屏视频广告
/// @param rootVC 用于 present 激励视频 VC
/// @param sceneId 广告位 id
- (void)showFullscreenVideoFromViewController:(UIViewController *)rootVC sceneId:(NSString *)sceneId {
    self.fullscreenVideoDelegate = rootVC;
    MEFullscreenManager *adManager = self.fullscreenManagers[sceneId];

    if (adManager) {
        [adManager showFullscreenVideoFromViewController:rootVC sceneId:sceneId];
        return;
    }
    
    // 没有合适的 adManager 表示当前没有广告可展示
    if (self.fullscreenVideoDelegate && [self.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenVideoAdFailed:)]) {
        NSError *error = [NSError errorWithDomain:@"no ads to show" code:0 userInfo:nil];
        [self.fullscreenVideoDelegate fullscreenVideoAdFailed:error];
    }
}
/// 关闭全屏视频广告
/// @param sceneId 广告位 id
- (void)stopFullscreenVideo:(NSString *)sceneId {
    if (sceneId == nil) {
        return;
    }
    MEFullscreenManager *adManager = self.fullscreenManagers[sceneId];

    if (adManager) {
        [adManager stopFullscreenVideoWithSceneId:sceneId];
        return;
    }
}
/// 当前广告位下是否有有效的全屏视频广告
- (BOOL)hasFullscreenVideoAvailableWithSceneId:(NSString *)sceneId {
    if (sceneId == nil) {
        return NO;
    }
    
    MEFullscreenManager *adManager = self.fullscreenManagers[sceneId];

    if (adManager) {
        return [adManager hasFullscreenVideoAvailableWithSceneId:sceneId];
    }
    
    return NO;
}

// MARK: - 信息流广告
- (void)loadFeedAdWithSize:(CGSize)size sceneId:(NSString *)sceneId delegate:(id)delegate count:(NSInteger)count {
    _target = delegate;
    
    if (self.isPlatformInit == NO) {
        // 若平台尚未初始化,则不执行
        return;
    }
    
    if (delegate == nil) {
        // 需要根据target给予action和响应
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    // 遵守代理
    //    self.feedAdManager = [MEFeedAdManager shareInstance];
    self.feedAdManager = [[MEFeedAdManager alloc] init];
    [self.feedAdManager loadFeedViewWithWidth:size.width sceneId:sceneId count:count finished:^(NSArray<UIView *> *feedViews) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.feedDelegate = delegate;
        [strongSelf feedViewFinishedOperation:feedViews];
    } failed:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.feedDelegate = delegate;
        [strongSelf feedViewFailedOpertion:error];
    }];
}

// MARK: - 信息流广告回调
/// 信息流广告展示成功后的操作
- (void)feedViewFinishedOperation:(NSArray *)feedViews {
    self.currentAdPlatform = self.feedAdManager.currentAdPlatform;
    
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(feedViewShowSuccess:feedViews:)]) {
        [self.feedDelegate feedViewLoadSuccess:self feedViews:feedViews];
    }
    
    // 广告展示成功
    self.feedAdManager.showFinished = ^(UIView * _Nonnull feedView) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.feedDelegate && [strongSelf.feedDelegate respondsToSelector:@selector(feedViewShowSuccess:feedView:)]) {
            [strongSelf.feedDelegate feedViewShowSuccess:strongSelf feedView:feedView];
        }
    };
    
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
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(feedViewShowFailure:)]) {
        [self.feedDelegate feedViewShowFailure:error];
    }
}

// MARK: - 激励视频广告回调
- (void)rewardVideoShowSuccessOperation {
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.rewardVideoDelegate && [self.rewardVideoDelegate respondsToSelector:@selector(rewardVideoLoadSuccess:)]) {
        [self.rewardVideoDelegate rewardVideoLoadSuccess:self];
    }
    
    // 视频展示成功
    self.rewardedVideoManager.showFinish = ^{
        if (self.rewardVideoDelegate && [self.rewardVideoDelegate respondsToSelector:@selector(rewardVideoShowSuccess:)]) {
            [self.rewardVideoDelegate rewardVideoShowSuccess:self];
        }
    };
    
    // 视频资源缓存成功
    self.rewardedVideoManager.didDownloadBlock = ^{
        if (self.rewardVideoDelegate && [self.rewardVideoDelegate respondsToSelector:@selector(rewardVideoDidDownloadSuccess:)]) {
            [self.rewardVideoDelegate rewardVideoDidDownloadSuccess:self];
        }
    };
    
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

// MARK: - 全屏视频广告回调
- (void)fullscreenVideoShowSuccessOperation {
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.fullscreenVideoDelegate && [self.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenVideoLoadSuccess:)]) {
        [self.fullscreenVideoDelegate fullscreenVideoLoadSuccess:self];
    }
    
    // 视频展示成功
    self.fullscreenManager.showFinish = ^{
        if (self.fullscreenVideoDelegate && [self.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenShowSuccess:)]) {
            [self.fullscreenVideoDelegate fullscreenShowSuccess:self];
        }
    };
    
    // 视频资源缓存成功
    self.fullscreenManager.didDownloadBlock = ^{
        if (self.fullscreenVideoDelegate && [self.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenDidDownloadSuccess:)]) {
            [self.fullscreenVideoDelegate fullscreenDidDownloadSuccess:self];
        }
    };
    
    // 视频播放完毕
    self.fullscreenManager.finishPlayBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.fullscreenVideoDelegate && [strongSelf.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenFinishPlay:)]) {
            [strongSelf.fullscreenVideoDelegate fullscreenFinishPlay:strongSelf];
        }
    };
    
    // 点击广告监听
    self.fullscreenManager.clickBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.fullscreenVideoDelegate && [strongSelf.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenClicked:)]) {
            [strongSelf.fullscreenVideoDelegate fullscreenClicked:strongSelf];
        }
    };
    
    // 关闭广告的监听
    self.fullscreenManager.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.fullscreenVideoDelegate && [strongSelf.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenClose:)]) {
            [strongSelf.fullscreenVideoDelegate fullscreenClose:strongSelf];
        }
    };
    
    // 点击跳过的监听
    self.fullscreenManager.skipBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.fullscreenVideoDelegate && [strongSelf.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenClickSkip:)]) {
            [strongSelf.fullscreenVideoDelegate fullscreenClickSkip:strongSelf];
        }
    };
}

/// 激励视频广告展示失败的操作
- (void)fullscreenVideoFailedOpertion:(NSError *)error {
    if (self.fullscreenVideoDelegate && [self.fullscreenVideoDelegate respondsToSelector:@selector(fullscreenVideoAdFailed:)]) {
        [self.fullscreenVideoDelegate fullscreenVideoAdFailed:error];
    }
}

// MARK: - 开屏广告回调
/// 开屏广告展示成功后的操作
- (void)splashFinishedOperation {
    self.currentAdPlatform = self.splashAdManager.currentAdPlatform;
    
    __weak typeof(self) weakSelf = self;
    // 广告加载成功
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(splashLoadSuccess:)]) {
        [self.splashDelegate splashLoadSuccess:self];
    }
    
    // 展示成功
    self.splashAdManager.showFinished = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.splashDelegate && [strongSelf.splashDelegate respondsToSelector:@selector(splashShowSuccess:)]) {
            [strongSelf.splashDelegate splashShowSuccess:strongSelf];
        }
    };
    
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
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(interstitialLoadSuccess:)]) {
        [self.interstitialDelegate interstitialLoadSuccess:self];
    }
    
    // 点击广告监听
    self.interstitialManager.clickBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.interstitialDelegate && [strongSelf.interstitialDelegate respondsToSelector:@selector(interstitialClicked:)]) {
            [strongSelf.interstitialDelegate interstitialClicked:strongSelf];
        }
    };
    
    self.interstitialManager.showFinishBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.interstitialDelegate && [strongSelf.interstitialDelegate respondsToSelector:@selector(interstitialShowSuccess:)]) {
            [strongSelf.interstitialDelegate interstitialShowSuccess:strongSelf];
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


// MARK: - Getter
- (NSMutableDictionary *)rewardedVideoManagers {
    if (!_rewardedVideoManagers) {
        _rewardedVideoManagers = [NSMutableDictionary dictionary];
    }
    return _rewardedVideoManagers;
}

- (NSMutableDictionary *)fullscreenManagers {
    if (!_fullscreenManagers) {
        _fullscreenManagers = [NSMutableDictionary dictionary];
    }
    return _fullscreenManagers;
}

- (NSMutableDictionary *)interstitialManagers {
    if (!_interstitialManagers) {
        _interstitialManagers = [NSMutableDictionary dictionary];
    }
    return _interstitialManagers;
}

@end
