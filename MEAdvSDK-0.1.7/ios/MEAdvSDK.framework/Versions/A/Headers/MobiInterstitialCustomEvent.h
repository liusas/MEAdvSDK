//
//  MobiInterstitialCustomEvent.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/18.
//

#import <Foundation/Foundation.h>
#import "MobiGlobal.h"

@protocol MobiInterstitialCustomEventDelegate;
@class MobiConfig;
@protocol MobiInterstitialCustomEvent <NSObject>

/**
 * 适用于custom event的键值对,mopub本意是,custom event可以由SDK外部去实现,这个字段用于传递一些custom evnet需要,而SDK中无法传递的字段,以localExtras传递,暂时保留这个字段,以便日后进行精细化拆分
 */
@property (nonatomic, copy) NSDictionary * localExtras;

@property (nonatomic, weak) id<MobiInterstitialCustomEventDelegate> delegate;

/// 当SDK请求拉取广告时,会调用此方法
/// 基类MobiFeedCustomEvent实现了MobiInterstitialCustomEvent接口
/// 这是必须实现的方法,基类不做任何事情,子类需要重写这个方法通过某种方式加载一个激励视频广告
/// Mopub本意是让这个框架适配聚合广告平台,因此一些mediationSettings我们不需要去考虑,因为自有SDK我们已经知道要传递什么参数
/// @param info custom event类请求广告需要传递的数据
/// @param adMarkup 广告标记,可为nil
- (void)requestInterstitialWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup;

/// 弹出广告
/// @param rootViewController 用来弹出信息流广告的根视图
- (void)showInterstitialAdFromViewController:(UIViewController *)rootViewController;

/// 在回传信息流广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable;

/// 子类重写次方法,决定由谁处理展现和点击上报
/// 默认return YES;由上层adapter处理展现和点击上报,
/// 若return NO;则由子类实现trackImpression和trackClick方法,实现上报,但要保证每个广告只上报一次
- (BOOL)enableAutomaticImpressionAndClickTracking;

/// 这个方法存在的意义是聚合广告,因为聚合广告可能会出现两个广告单元用同一个广告平台加载广告
/// 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
/// 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
/// 并且我们要重写这个方法,让这个Custom event类能释放掉
/// 默认这个方法不会做任何事情
- (void)handleAdPlayedForCustomEventNetwork;

/// 在激励视频系统不再需要这个custom event类时,会调用这个方法,目的是让custom event能够成功释放掉,如果能保证custom event不会造成内存泄漏,则这个方法不用重写
- (void)handleCustomEventInvalidated;

@end

@interface MobiInterstitialCustomEvent : NSObject<MobiInterstitialCustomEvent>

@property (nonatomic, copy) NSDictionary * localExtras;
@property (nonatomic, weak) id<MobiInterstitialCustomEventDelegate> delegate;

@end

@protocol MobiInterstitialCustomEventDelegate <NSObject>

/**
 *  插屏2.0广告预加载成功回调
 *  当接收服务器返回的广告数据成功且预加载后调用该函数
 */
- (void)unifiedInterstitialSuccessToLoadAdForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  插屏2.0广告预加载失败回调
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedInterstitialFailToLoadAdForCustomEvent:(MobiInterstitialCustomEvent *)customEvent error:(NSError *)error;

/**
 *  插屏2.0广告将要展示回调
 *  插屏2.0广告即将展示回调该函数
 */
- (void)unifiedInterstitialWillPresentScreenForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  插屏2.0广告视图展示成功回调
 *  插屏2.0广告展示成功回调该函数
 */
- (void)unifiedInterstitialDidPresentScreenForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  插屏2.0广告视图展示失败回调
 *  插屏2.0广告展示失败回调该函数
 */
- (void)unifiedInterstitialFailToPresentForCustomEvent:(MobiInterstitialCustomEvent *)customEvent error:(NSError *)error;

/**
 *  插屏2.0广告展示结束回调
 *  插屏2.0广告展示结束回调该函数
 */
- (void)unifiedInterstitialDidDismissScreenForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  当点击下载应用时会调用系统程序打开其它App或者Appstore时回调
 */
- (void)unifiedInterstitialWillLeaveApplicationForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  插屏2.0广告曝光回调
 */
- (void)unifiedInterstitialWillExposureForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  插屏2.0广告点击回调
 */
- (void)unifiedInterstitialClickedForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  点击插屏2.0广告以后即将弹出全屏广告页
 */
- (void)unifiedInterstitialAdWillPresentFullScreenModalForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  点击插屏2.0广告以后弹出全屏广告页
 */
- (void)unifiedInterstitialAdDidPresentFullScreenModalForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  全屏广告页将要关闭
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModalForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 *  全屏广告页被关闭
 */
- (void)unifiedInterstitialAdDidDismissFullScreenModalForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)unifiedInterstitialAdDidExpireForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 * 插屏2.0视频广告 player 播放状态更新回调
 */
- (void)unifiedInterstitialAdForCustomEvent:(MobiInterstitialCustomEvent *)customEvent playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 插屏2.0视频广告详情页 WillPresent 回调
 */
- (void)unifiedInterstitialAdViewWillPresentVideoVCForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 * 插屏2.0视频广告详情页 DidPresent 回调
 */
- (void)unifiedInterstitialAdViewDidPresentVideoVCForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 * 插屏2.0视频广告详情页 WillDismiss 回调
 */
- (void)unifiedInterstitialAdViewWillDismissVideoVCForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

/**
 * 插屏2.0视频广告详情页 DidDismiss 回调
 */
- (void)unifiedInterstitialAdViewDidDismissVideoVCForCustomEvent:(MobiInterstitialCustomEvent *)customEvent;

@end

