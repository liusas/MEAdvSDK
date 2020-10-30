//
//  MobiInterstitialAdapter.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/18.
//

#import <Foundation/Foundation.h>
#import "MobiGlobal.h"

@class MobiConfig;
@class MobiAdTargeting;
@protocol MobiInterstitialAdapterDelegate;

@interface MobiInterstitialAdapter : NSObject

@property (nonatomic, weak) id<MobiInterstitialAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<MobiInterstitialAdapterDelegate>)delegate;

/**
 * 当我们从服务器获得响应时,调用此方法获取一个广告
 *
 * @param configuration 加载广告所需的一些配置信息
 8 @param targeting 获取精准化广告目标所需的一些参数
 */
- (void)getAdWithConfiguration:(MobiConfig *)configuration targeting:(MobiAdTargeting *)targeting;


/// 弹出广告
/// @param rootViewController 用来弹出信息流广告的根视图
- (void)showInterstitialAdFromViewController:(UIViewController *)rootViewController;

/**
 * 判断现在是否有可用的广告可供展示
 */
- (BOOL)hasAdAvailable;

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调`[-nativeExpressAdDidExpireForAdapter:]`方法告诉用户这个广告已不再有效
*/
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiInterstitialAdapterDelegate <NSObject>

/**
 *  插屏2.0广告预加载成功回调
 *  当接收服务器返回的广告数据成功且预加载后调用该函数
 */
- (void)unifiedInterstitialSuccessToLoadAdForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  插屏2.0广告预加载失败回调
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedInterstitialFailToLoadAdForAdapter:(MobiInterstitialAdapter *)adapter error:(NSError *)error;

/**
 *  插屏2.0广告将要展示回调
 *  插屏2.0广告即将展示回调该函数
 */
- (void)unifiedInterstitialWillPresentScreenForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  插屏2.0广告视图展示成功回调
 *  插屏2.0广告展示成功回调该函数
 */
- (void)unifiedInterstitialDidPresentScreenForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  插屏2.0广告视图展示失败回调
 *  插屏2.0广告展示失败回调该函数
 */
- (void)unifiedInterstitialFailToPresentForAdapter:(MobiInterstitialAdapter *)adapter error:(NSError *)error;

/**
 *  插屏2.0广告展示结束回调
 *  插屏2.0广告展示结束回调该函数
 */
- (void)unifiedInterstitialDidDismissScreenForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  当点击下载应用时会调用系统程序打开其它App或者Appstore时回调
 */
- (void)unifiedInterstitialWillLeaveApplicationForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  插屏2.0广告曝光回调
 */
- (void)unifiedInterstitialWillExposureForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  插屏2.0广告点击回调
 */
- (void)unifiedInterstitialClickedForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  点击插屏2.0广告以后即将弹出全屏广告页
 */
- (void)unifiedInterstitialAdWillPresentFullScreenModalForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  点击插屏2.0广告以后弹出全屏广告页
 */
- (void)unifiedInterstitialAdDidPresentFullScreenModalForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  全屏广告页将要关闭
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModalForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 *  全屏广告页被关闭
 */
- (void)unifiedInterstitialAdDidDismissFullScreenModalForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)unifiedInterstitialAdDidExpireForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 * 插屏2.0视频广告 player 播放状态更新回调
 */
- (void)unifiedInterstitialAdForAdapter:(MobiInterstitialAdapter *)adapter playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 插屏2.0视频广告详情页 WillPresent 回调
 */
- (void)unifiedInterstitialAdViewWillPresentVideoVCForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 * 插屏2.0视频广告详情页 DidPresent 回调
 */
- (void)unifiedInterstitialAdViewDidPresentVideoVCForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 * 插屏2.0视频广告详情页 WillDismiss 回调
 */
- (void)unifiedInterstitialAdViewWillDismissVideoVCForAdapter:(MobiInterstitialAdapter *)adapter;

/**
 * 插屏2.0视频广告详情页 DidDismiss 回调
 */
- (void)unifiedInterstitialAdViewDidDismissVideoVCForAdapter:(MobiInterstitialAdapter *)adapter;

@end
