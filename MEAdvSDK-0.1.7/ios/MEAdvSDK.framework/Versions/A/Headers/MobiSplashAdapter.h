//
//  MobiSplashAdapter.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import <Foundation/Foundation.h>
#import "MobiPrivateSplashCustomEventDelegate.h"

@class MobiConfig;
@class MobiAdTargeting;

@protocol MobiSplashAdapterDelegate;

@interface MobiSplashAdapter : NSObject<MobiPrivateSplashCustomEventDelegate>

@property (nonatomic, weak) id<MobiSplashAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<MobiSplashAdapterDelegate>)delegate;

/**
 * 当我们从服务器获得响应时,调用此方法获取一个广告
 *
 * @param configuration 加载广告所需的一些配置信息
 8 @param targeting 获取精准化广告目标所需的一些参数
 */
- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting;

/**
 * 判断现在是否有可用的广告可供展示
 */
- (BOOL)hasAdAvailable;

/**
 * 播放一个激励视频
 *
 * @param window 用来弹出播放器控制器的控制器
 */
- (void)presentSplashFromWindow:(UIWindow *)window;

/**
* 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
* 当然广告失效后需要回调`[-splashAdDidExpireForAdapter:]`方法告诉用户这个广告已不再有效
*/
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiSplashAdapterDelegate <NSObject>

/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForAdapter:(MobiSplashAdapter *)splashAd withError:(NSError *)error;

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForAdapter:(MobiSplashAdapter *)splashAd;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpireForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd;

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForAdapter:(MobiSplashAdapter *)splashAd;

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdLifeTime:(NSUInteger)time;

@optional
- (NSString *)splashAdUnitId;
- (NSString *)splashUserId;
- (MobiConfig *)configuration;

@end
