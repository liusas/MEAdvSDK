//
//  MobiSplashAdManager.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import <Foundation/Foundation.h>
#import "MobiAdTargeting.h"

@protocol MobiSplashAdManagerDelegate;

@interface MobiSplashAdManager : NSObject

@property (nonatomic, weak) id<MobiSplashAdManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *posid;
/// 用户唯一标识
@property (nonatomic, copy) NSString *userId;
/// 广告的一些配置信息
@property (nonatomic, strong) MobiAdTargeting *targeting;

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiSplashAdManagerDelegate>)delegate;

/**
 * 加载开屏广告
 * @param userId 用户的唯一标识
 * @param targeting 精准广告投放的一些参数,可为空
 */
- (void)loadSplashAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting;

/**
 * 判断这个ad manager下的广告是否是有效且可以直接展示的
 */
- (BOOL)hasAdAvailable;

/**
 * 弹出激励视频广告
 *
 * @param window 用来present出视频控制器的控制器
 */
- (void)presentSplashAdFromWindow:(UIWindow *)window;
/**
 * 停止开屏广告
 */
- (void)stopSplashAdWithPosid:(NSString *)posid;

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
 */
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiSplashAdManagerDelegate <NSObject>

/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForManager:(MobiSplashAdManager *)splashAd withError:(NSError *)error;

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForManager:(MobiSplashAdManager *)splashAd;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpireForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForManager:(MobiSplashAdManager *)splashAd;

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForManager:(MobiSplashAdManager *)splashAd;

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForManager:(MobiSplashAdManager *)splashAd;

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForManager:(MobiSplashAdManager *)splashAd;

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdForManager:(MobiSplashAdManager *)splashAd lifeTime:(NSUInteger)time;

@end

