//
//  MobiDrawViewAdManager.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"

@protocol MobiDrawViewAdManagerDelegate;
@class MobiNativeExpressDrawView;

@interface MobiDrawViewAdManager : NSObject

@property (nonatomic, weak) id<MobiDrawViewAdManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *posid;

// 信息流数量
@property (nonatomic, assign) NSInteger count;
/// 用户唯一标识
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) MobiAdTargeting *targeting;

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiDrawViewAdManagerDelegate>)delegate;

/**
* 加载信息流广告
* @param userId 用户的唯一标识
* @param targeting 精准广告投放的一些参数,可为空
*/
- (void)loadDrawViewAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting;

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

@protocol MobiDrawViewAdManagerDelegate <NSObject>

/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoadForAdManager:(MobiDrawViewAdManager *)adManager views:(NSArray<__kindof MobiNativeExpressDrawView *> *)views;

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoadForAdManager:(MobiDrawViewAdManager *)adManager error:(NSError *)error;

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)nativeExpressAdDidExpireForAdManager:(MobiDrawViewAdManager *)adManager;

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackgroundForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdViewForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVCForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVCForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVCForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVCForAdManager:(MobiDrawViewAdManager *)adManager views:(MobiNativeExpressDrawView *)nativeExpressAdView;

@end

