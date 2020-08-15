//
//  MobiFeedAdManager.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"

@protocol MobiFeedAdManagerDelegate;
@class MobiNativeExpressFeedView;

@interface MobiFeedAdManager : NSObject

@property (nonatomic, weak) id<MobiFeedAdManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *posid;
/// 用户唯一标识
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) MobiAdTargeting *targeting;

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiFeedAdManagerDelegate>)delegate;

/**
* 加载信息流广告
* @param userId 用户的唯一标识
* @param targeting 精准广告投放的一些参数,可为空
*/
- (void)loadFeedAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting;

/**
 * 判断这个ad manager下的广告是否是有效且可以直接展示的
 */
- (BOOL)hasAdAvailable;

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调`[-nativeExpressAdDidExpireForAdManager:]`方法告诉用户这个广告已不再有效
 */
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiFeedAdManagerDelegate <NSObject>

/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoadForAdManager:(MobiFeedAdManager *)adManager views:(NSArray<__kindof MobiNativeExpressFeedView *> *)views;

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoadForAdManager:(MobiFeedAdManager *)adManager error:(NSError *)error;

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)nativeExpressAdDidExpireForAdManager:(MobiFeedAdManager *)adManager;

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackgroundForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdViewForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVCForAdManager:(MobiFeedAdManager *)adManager views:(MobiNativeExpressFeedView *)nativeExpressAdView;

@end

