//
//  MobiInterstitialManager.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/18.
//

#import <Foundation/Foundation.h>
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"

@protocol MobiInterstitialManagerDelegate;

@interface MobiInterstitialManager : NSObject

@property (nonatomic, weak) id<MobiInterstitialManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *posid;
/// 用户唯一标识
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) MobiAdTargeting *targeting;

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiInterstitialManagerDelegate>)delegate;

/**
* 加载信息流广告
* @param userId 用户的唯一标识
* @param targeting 精准广告投放的一些参数,可为空
*/
- (void)loadInterstitialAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting;

/**
 * 判断这个ad manager下的广告是否是有效且可以直接展示的
 */
- (BOOL)hasAdAvailable;

/**
 *  弹出信息流广告
 *  @param rootViewController 用来弹出信息流广告的根视图
 */
- (void)showInterstitialAdFromViewController:(UIViewController *)rootViewController;

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调`[-nativeExpressAdDidExpireForAdManager:]`方法告诉用户这个广告已不再有效
 */
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiInterstitialManagerDelegate <NSObject>

@optional

/**
 *  插屏2.0广告预加载成功回调
 *  当接收服务器返回的广告数据成功且预加载后调用该函数
 */
- (void)unifiedInterstitialSuccessToLoadAdForManager:(MobiInterstitialManager *)adManager;

/**
 *  插屏2.0广告预加载失败回调
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedInterstitialFailToLoadAdForManager:(MobiInterstitialManager *)adManager error:(NSError *)error;

/**
 *  插屏2.0广告将要展示回调
 *  插屏2.0广告即将展示回调该函数
 */
- (void)unifiedInterstitialWillPresentScreenForManager:(MobiInterstitialManager *)adManager;

/**
 *  插屏2.0广告视图展示成功回调
 *  插屏2.0广告展示成功回调该函数
 */
- (void)unifiedInterstitialDidPresentScreenForManager:(MobiInterstitialManager *)adManager;

/**
 *  插屏2.0广告视图展示失败回调
 *  插屏2.0广告展示失败回调该函数
 */
- (void)unifiedInterstitialFailToPresentForManager:(MobiInterstitialManager *)adManager error:(NSError *)error;

/**
 *  插屏2.0广告展示结束回调
 *  插屏2.0广告展示结束回调该函数
 */
- (void)unifiedInterstitialDidDismissScreenForManager:(MobiInterstitialManager *)adManager;

/**
 *  当点击下载应用时会调用系统程序打开其它App或者Appstore时回调
 */
- (void)unifiedInterstitialWillLeaveApplicationForManager:(MobiInterstitialManager *)adManager;

/**
 *  插屏2.0广告曝光回调
 */
- (void)unifiedInterstitialWillExposureForManager:(MobiInterstitialManager *)adManager;

/**
 *  插屏2.0广告点击回调
 */
- (void)unifiedInterstitialClickedForManager:(MobiInterstitialManager *)adManager;

/**
 *  点击插屏2.0广告以后即将弹出全屏广告页
 */
- (void)unifiedInterstitialAdWillPresentFullScreenModalForManager:(MobiInterstitialManager *)adManager;

/**
 *  点击插屏2.0广告以后弹出全屏广告页
 */
- (void)unifiedInterstitialAdDidPresentFullScreenModalForManager:(MobiInterstitialManager *)adManager;

/**
 *  全屏广告页将要关闭
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModalForManager:(MobiInterstitialManager *)adManager;

/**
 *  全屏广告页被关闭
 */
- (void)unifiedInterstitialAdDidDismissFullScreenModalForManager:(MobiInterstitialManager *)adManager;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)unifiedInterstitialAdDidExpireForManager:(MobiInterstitialManager *)adManager;

/**
 * 插屏2.0视频广告 player 播放状态更新回调
 */
- (void)unifiedInterstitialAdForManager:(MobiInterstitialManager *)adManager playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 插屏2.0视频广告详情页 WillPresent 回调
 */
- (void)unifiedInterstitialAdViewWillPresentVideoVCForManager:(MobiInterstitialManager *)adManager;

/**
 * 插屏2.0视频广告详情页 DidPresent 回调
 */
- (void)unifiedInterstitialAdViewDidPresentVideoVCForManager:(MobiInterstitialManager *)adManager;

/**
 * 插屏2.0视频广告详情页 WillDismiss 回调
 */
- (void)unifiedInterstitialAdViewWillDismissVideoVCForManager:(MobiInterstitialManager *)adManager;

/**
 * 插屏2.0视频广告详情页 DidDismiss 回调
 */
- (void)unifiedInterstitialAdViewDidDismissVideoVCForManager:(MobiInterstitialManager *)adManager;

@end
