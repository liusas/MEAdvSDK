//
//  MobiFeed.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import "MobiFeed.h"
#import "MobiFeedAdManager.h"
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"
#import "MobiFeedError.h"
#import "MobiFeedModel.h"

static MobiFeed *gSharedInstance = nil;

@interface MobiFeed ()<MobiFeedAdManagerDelegate>

@property (nonatomic, strong) NSMutableDictionary *feedAdManagers;
/// 存放不同posid对应的delegate
@property (nonatomic, strong) NSMapTable<NSString *, id<MobiFeedDelegate>> * delegateTable;

+ (MobiFeed *)sharedInstance;

@end

@implementation MobiFeed

- (instancetype)init {
    if (self = [super init]) {
        _feedAdManagers = [[NSMutableDictionary alloc] init];

        // Keys (ad unit ID) are strong, values (delegates) are weak.
        _delegateTable = [NSMapTable strongToWeakObjectsMapTable];
    }

    return self;
}

/// 设置用来接收posid对应的信息流回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiFeedDelegate>)delegate forPosid:(NSString *)posid {
    if (posid == nil) {
        return;
    }
    
    [[[self class] sharedInstance].delegateTable setObject:delegate forKey:posid];
}

/// 从有效的posid中删除对应的接收信息流的回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiFeedDelegate>)delegate {
    if (delegate == nil) {
        return;
    }

    NSMapTable * mapTable = [[self class] sharedInstance].delegateTable;

    NSMutableArray<NSString *> * keys = [NSMutableArray array];
    for (NSString * key in mapTable) {
        if ([mapTable objectForKey:key] == delegate) {
            [keys addObject:key];
        }
    }

    for (NSString * key in keys) {
        [mapTable removeObjectForKey:key];
    }
}

/// 删除posid对应的delegate
/// @param posid 广告位id
+ (void)removeDelegateForPosid:(NSString *)posid {
    if (posid == nil) {
        return;
    }

    [[[self class] sharedInstance].delegateTable removeObjectForKey:posid];
}

+ (void)loadFeedAdWithPosid:(NSString *)posid feedModel:(MobiFeedModel *)model {
    MobiFeed *sharedInstance = [[self class] sharedInstance];
    
    if (![posid length]) {
        NSError *error = [NSError errorWithDomain:MobiFeedAdsSDKDomain code:MobiFeedAdErrorInvalidPosid userInfo:nil];
        id<MobiFeedDelegate> delegate = [sharedInstance.delegateTable objectForKey:posid];
        [delegate nativeExpressAdFailToLoad:sharedInstance error:error];
        return;
    }
    
    if (model != nil) {
        sharedInstance.feedModel = model;
    }
    sharedInstance.posid = posid;
    
    MobiFeedAdManager *adManager = sharedInstance.feedAdManagers[posid];

    if (!adManager) {
        adManager = [[MobiFeedAdManager alloc] initWithPosid:posid delegate:sharedInstance];
        sharedInstance.feedAdManagers[posid] = adManager;
    }

    // 广告目标锁定,都是便于更精准的投放广告
    MobiAdTargeting *targeting = [MobiAdTargeting targetingWithCreativeSafeSize:MPApplicationFrame(YES).size];
    targeting.keywords = model.keywords;
    targeting.localExtras = model.localExtras;
    targeting.userDataKeywords = model.userDataKeywords;
    targeting.feedSize = model.feedSize;
    [adManager loadFeedAdWithUserId:model.userId targeting:targeting];
}

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid {
    MobiFeed *sharedInstance = [[self class] sharedInstance];
    MobiFeedAdManager *adManager = sharedInstance.feedAdManagers[posid];

    return [adManager hasAdAvailable];
}

// MARK: - MobiFeedAdManagerDelegate
/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoadForAdManager:(MobiFeedAdManager *)adManager views:(NSArray<__kindof MobiNativeExpressFeedView *> *)views {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdSuccessToLoad:views:)]) {
        [delegate nativeExpressAdSuccessToLoad:self views:views];
    }
}

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoadForAdManager:(MobiFeedAdManager *)adManager error:(NSError *)error {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdFailToLoad:error:)]) {
        [delegate nativeExpressAdFailToLoad:self error:error];
    }
}

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewRenderSuccess:)]) {
        [delegate nativeExpressAdViewRenderSuccess:nativeExpressAdView];
    }
}

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewRenderFail:)]) {
        [delegate nativeExpressAdViewRenderFail:nativeExpressAdView];
    }
}

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewExposure:)]) {
        [delegate nativeExpressAdViewExposure:nativeExpressAdView];
    }
}

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewClicked:)]) {
        [delegate nativeExpressAdViewClicked:nativeExpressAdView];
    }
}

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewClosed:)]) {
        [delegate nativeExpressAdViewClosed:nativeExpressAdView];
    }
}

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)nativeExpressAdDidExpireForAdManager:(MobiFeedAdManager *)adManager {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdDidExpire:)]) {
        [delegate nativeExpressAdDidExpire:self];
    }
}

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewWillPresentScreen:)]) {
        [delegate nativeExpressAdViewWillPresentScreen:nativeExpressAdView];
    }
}

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewDidPresentScreen:)]) {
        [delegate nativeExpressAdViewDidPresentScreen:nativeExpressAdView];
    }
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewWillDissmissScreen:)]) {
        [delegate nativeExpressAdViewWillDissmissScreen:nativeExpressAdView];
    }
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewDidDissmissScreen:)]) {
        [delegate nativeExpressAdViewDidDissmissScreen:nativeExpressAdView];
    }
}

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackgroundForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewApplicationWillEnterBackground:)]) {
        [delegate nativeExpressAdViewApplicationWillEnterBackground:nativeExpressAdView];
    }
}

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdViewForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView playerStatusChanged:(MobiMediaPlayerStatus)status {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdView:playerStatusChanged:)]) {
        [delegate nativeExpressAdView:nativeExpressAdView playerStatusChanged:status];
    }
}

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewWillPresentVideoVC:)]) {
        [delegate nativeExpressAdViewWillPresentVideoVC:nativeExpressAdView];
    }
}

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewDidPresentVideoVC:)]) {
        [delegate nativeExpressAdViewDidPresentVideoVC:nativeExpressAdView];
    }
}

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewWillDismissVideoVC:)]) {
        [delegate nativeExpressAdViewWillDismissVideoVC:nativeExpressAdView];
    }
}

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView {
    id<MobiFeedDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(nativeExpressAdViewDidDismissVideoVC:)]) {
        [delegate nativeExpressAdViewDidDismissVideoVC:nativeExpressAdView];
    }
}

// MARK: - Private

+ (MobiFeed *)sharedInstance
{
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        gSharedInstance = [[self alloc] init];
    });

    return gSharedInstance;
}

@end
