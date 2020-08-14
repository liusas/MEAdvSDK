//
//  MobiInterstitial.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/18.
//

#import "MobiInterstitial.h"
#import "MobiInterstitialManager.h"
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"
#import "MobiInterstitialError.h"
#import "MobiInterstitialModel.h"

static MobiInterstitial *gSharedInstance = nil;

@interface MobiInterstitial ()<MobiInterstitialManagerDelegate>

@property (nonatomic, strong) NSMutableDictionary *interstitialAdManagers;
/// 存放不同posid对应的delegate
@property (nonatomic, strong) NSMapTable<NSString *, id<MobiInterstitialDelegate>> * delegateTable;

+ (MobiInterstitial *)sharedInstance;

@end

@implementation MobiInterstitial

/// 设置用来接收posid对应的信息流回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiInterstitialDelegate>)delegate forPosid:(NSString *)posid {
    if (posid == nil) {
        return;
    }
    
    [[[self class] sharedInstance].delegateTable setObject:delegate forKey:posid];
}

/// 从有效的posid中删除对应的接收信息流回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiInterstitialDelegate>)delegate {
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

/// 加载信息流广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid,count,videoAutoPlayOnWWAN,videoMuted等),可为nil
+ (void)loadInterstitialAdWithPosid:(NSString *)posid interstitialModel:(MobiInterstitialModel *)model {
    MobiInterstitial *sharedInstance = [[self class] sharedInstance];
    
    if (![posid length]) {
        NSError *error = [NSError errorWithDomain:MobiInterstitialAdsSDKDomain code:MobiInterstitialAdErrorInvalidPosid userInfo:nil];
        id<MobiInterstitialDelegate> delegate = [sharedInstance.delegateTable objectForKey:posid];
        [delegate unifiedInterstitialFailToLoadAd:sharedInstance error:error];
        return;
    }
    
    if (model != nil) {
        sharedInstance.interstitialModel = model;
    }
    sharedInstance.posid = posid;
    
    MobiInterstitialManager *adManager = sharedInstance.interstitialAdManagers[posid];

    if (!adManager) {
        adManager = [[MobiInterstitialManager alloc] initWithPosid:posid delegate:sharedInstance];
        sharedInstance.interstitialAdManagers[posid] = adManager;
    }

    // 广告目标锁定,都是便于更精准的投放广告
    MobiAdTargeting *targeting = [MobiAdTargeting targetingWithCreativeSafeSize:MPApplicationFrame(YES).size];
    targeting.keywords = model.keywords;
    targeting.localExtras = model.localExtras;
    targeting.userDataKeywords = model.userDataKeywords;
    [adManager loadInterstitialAdWithUserId:model.userId targeting:targeting];
}

/// 弹出信息流广告
/// @param viewController 用来弹出信息流广告的根视图
+ (void)showInterstitialAdFromViewController:(UIViewController *)viewController posid:(NSString *)posid {
    MobiInterstitial *sharedInstance = [[self class] sharedInstance];
    MobiInterstitialManager *adManager = sharedInstance.interstitialAdManagers[posid];
    
    if (!adManager) {
        //        MPLogInfo(@"The rewarded video could not be shown: "
        //                  @"no ads have been loaded for adUnitID: %@", adUnitID);
        
        return;
    }
    
    if (!viewController) {
        //        MPLogInfo(@"The rewarded video could not be shown: "
        //                  @"a nil view controller was passed to -presentRewardedVideoAdForAdUnitID:fromViewController:.");
        
        return;
    }
    
    if (![viewController.view.window isKeyWindow]) {
        //        MPLogInfo(@"Attempting to present a rewarded video ad in non-key window. The ad may not render properly.");
    }
    
    [adManager showInterstitialAdFromViewController:viewController];
}

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid {
    MobiInterstitial *sharedInstance = [[self class] sharedInstance];
    MobiInterstitialManager *adManager = sharedInstance.interstitialAdManagers[posid];

    return [adManager hasAdAvailable];
}

// MARK: - MobiInterstitialManagerDelegate
/**
 *  插屏2.0广告预加载成功回调
 *  当接收服务器返回的广告数据成功且预加载后调用该函数
 */
- (void)unifiedInterstitialSuccessToLoadAdForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialSuccessToLoadAd:)]) {
        [delegate unifiedInterstitialSuccessToLoadAd:self];
    }
}

/**
 *  插屏2.0广告预加载失败回调
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedInterstitialFailToLoadAdForManager:(MobiInterstitialManager *)adManager error:(NSError *)error {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialFailToLoadAd:error:)]) {
        [delegate unifiedInterstitialFailToLoadAd:self error:error];
    }
}

/**
 *  插屏2.0广告将要展示回调
 *  插屏2.0广告即将展示回调该函数
 */
- (void)unifiedInterstitialWillPresentScreenForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialWillPresentScreen:)]) {
        [delegate unifiedInterstitialWillPresentScreen:self];
    }
}

/**
 *  插屏2.0广告视图展示成功回调
 *  插屏2.0广告展示成功回调该函数
 */
- (void)unifiedInterstitialDidPresentScreenForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialDidPresentScreen:)]) {
        [delegate unifiedInterstitialDidPresentScreen:self];
    }
}

/**
 *  插屏2.0广告视图展示失败回调
 *  插屏2.0广告展示失败回调该函数
 */
- (void)unifiedInterstitialFailToPresentForManager:(MobiInterstitialManager *)adManager error:(NSError *)error {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialFailToPresent:error:)]) {
        [delegate unifiedInterstitialFailToPresent:self error:error];
    }
}

/**
 *  插屏2.0广告展示结束回调
 *  插屏2.0广告展示结束回调该函数
 */
- (void)unifiedInterstitialDidDismissScreenForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialDidDismissScreen:)]) {
        [delegate unifiedInterstitialDidDismissScreen:self];
    }
}

/**
 *  当点击下载应用时会调用系统程序打开其它App或者Appstore时回调
 */
- (void)unifiedInterstitialWillLeaveApplicationForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialWillLeaveApplication:)]) {
        [delegate unifiedInterstitialWillLeaveApplication:self];
    }
}

/**
 *  插屏2.0广告曝光回调
 */
- (void)unifiedInterstitialWillExposureForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialWillExposure:)]) {
        [delegate unifiedInterstitialWillExposure:self];
    }
}

/**
 *  插屏2.0广告点击回调
 */
- (void)unifiedInterstitialClickedForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialClicked:)]) {
        [delegate unifiedInterstitialClicked:self];
    }
}

/**
 *  点击插屏2.0广告以后即将弹出全屏广告页
 */
- (void)unifiedInterstitialAdWillPresentFullScreenModalForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdWillPresentFullScreenModal:)]) {
        [delegate unifiedInterstitialAdWillPresentFullScreenModal:self];
    }
}

/**
 *  点击插屏2.0广告以后弹出全屏广告页
 */
- (void)unifiedInterstitialAdDidPresentFullScreenModalForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdDidPresentFullScreenModal:)]) {
        [delegate unifiedInterstitialAdDidPresentFullScreenModal:self];
    }
}

/**
 *  全屏广告页将要关闭
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModalForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdWillDismissFullScreenModal:)]) {
        [delegate unifiedInterstitialAdWillDismissFullScreenModal:self];
    }
}

/**
 *  全屏广告页被关闭
 */
- (void)unifiedInterstitialAdDidDismissFullScreenModalForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdDidDismissFullScreenModal:)]) {
        [delegate unifiedInterstitialAdDidDismissFullScreenModal:self];
    }
}

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)unifiedInterstitialAdDidExpireForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdDidExpire:)]) {
        [delegate unifiedInterstitialAdDidExpire:self];
    }
}

/**
 * 插屏2.0视频广告 player 播放状态更新回调
 */
- (void)unifiedInterstitialAdForManager:(MobiInterstitialManager *)adManager playerStatusChanged:(MobiMediaPlayerStatus)status {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAd:playerStatusChanged:)]) {
        [delegate unifiedInterstitialAd:self playerStatusChanged:status];
    }
}

/**
 * 插屏2.0视频广告详情页 WillPresent 回调
 */
- (void)unifiedInterstitialAdViewWillPresentVideoVCForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdViewWillPresentVideoVC:)]) {
        [delegate unifiedInterstitialAdViewWillPresentVideoVC:self];
    }
}

/**
 * 插屏2.0视频广告详情页 DidPresent 回调
 */
- (void)unifiedInterstitialAdViewDidPresentVideoVCForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdViewDidPresentVideoVC:)]) {
        [delegate unifiedInterstitialAdViewDidPresentVideoVC:self];
    }
}

/**
 * 插屏2.0视频广告详情页 WillDismiss 回调
 */
- (void)unifiedInterstitialAdViewWillDismissVideoVCForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdViewWillDismissVideoVC:)]) {
        [delegate unifiedInterstitialAdViewWillDismissVideoVC:self];
    }
}

/**
 * 插屏2.0视频广告详情页 DidDismiss 回调
 */
- (void)unifiedInterstitialAdViewDidDismissVideoVCForManager:(MobiInterstitialManager *)adManager {
    id<MobiInterstitialDelegate> delegate = [self.delegateTable objectForKey:adManager.posid];
    if ([delegate respondsToSelector:@selector(unifiedInterstitialAdViewDidDismissVideoVC:)]) {
        [delegate unifiedInterstitialAdViewDidDismissVideoVC:self];
    }
}

@end
