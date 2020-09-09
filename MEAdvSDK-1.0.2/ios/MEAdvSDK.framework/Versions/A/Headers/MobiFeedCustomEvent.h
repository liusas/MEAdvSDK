//
//  MobiFeedCustomEvent.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "MobiGlobal.h"

@protocol MobiFeedCustomEventDelegate;
@class MobiNativeExpressFeedView;
@class MobiConfig;

@protocol MobiFeedCustomEvent <NSObject>

/**
 * 适用于custom event的键值对,mopub本意是,custom event可以由SDK外部去实现,这个字段用于传递一些custom evnet需要,而SDK中无法传递的字段,以localExtras传递,暂时保留这个字段,以便日后进行精细化拆分
 */
@property (nonatomic, copy) NSDictionary * localExtras;

@property (nonatomic, weak) id<MobiFeedCustomEventDelegate> delegate;

/// 当SDK请求拉取广告时,会调用此方法
/// 基类MobiFeedCustomEvent实现了MobiFeedCustomEvent接口
/// 这是必须实现的方法,基类不做任何事情,子类需要重写这个方法通过某种方式加载一个激励视频广告
/// Mopub本意是让这个框架适配聚合广告平台,因此一些mediationSettings我们不需要去考虑,因为自有SDK我们已经知道要传递什么参数
/// @param info custom event类请求广告需要传递的数据
/// @param adMarkup 广告标记,可为nil
- (void)requestFeedWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup;

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

@interface MobiFeedCustomEvent : NSObject<MobiFeedCustomEvent>

@property (nonatomic, copy) NSDictionary * localExtras;
@property (nonatomic, weak) id<MobiFeedCustomEventDelegate> delegate;

@end

@protocol MobiFeedCustomEventDelegate <NSObject>
/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoadForCustomEvent:(MobiFeedCustomEvent *)customEvent views:(NSArray<__kindof MobiNativeExpressFeedView *> *)views;

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoadForCustomEvent:(MobiFeedCustomEvent *)customEvent error:(NSError *)error;

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)nativeExpressAdDidExpireForCustomEvent:(MobiFeedCustomEvent *)customEvent;

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackgroundForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdViewForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVCForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVCForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVCForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVCForCustomEvent:(MobiNativeExpressFeedView *)nativeExpressAdView;

@optional
/// 调用这个代理方法,从上层获取userid用户唯一标识
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (NSString *)customerIdForFeedCustomEvent:(id<MobiFeedCustomEvent>)customEvent;

/// 调用此方法上报广告展示事件
/// 调用此代理的前提是`enableAutomaticImpressionAndClickTracking`返回NO,及不允许上层自动上报,一般没必要这样设置
- (void)trackImpression;

/// 调用此方法上报广告点击事件
/// 调用此代理的前提是`enableAutomaticImpressionAndClickTracking`返回NO,及不允许上层自动上报,一般没必要这样设置
- (void)trackClick;

@end
