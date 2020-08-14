//
//  MobiFeedAdapter.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "MobiPrivateFeedCustomEvent.h"
#import "MobiGlobal.h"

@class MobiConfig;
@class MobiAdTargeting;
@class MobiNativeExpressFeedView;

@protocol MobiFeedAdapterDelegate;

@interface MobiFeedAdapter : NSObject

@property (nonatomic, weak) id<MobiFeedAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<MobiFeedAdapterDelegate>)delegate;

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
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调`[-nativeExpressAdDidExpireForAdapter:]`方法告诉用户这个广告已不再有效
*/
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiFeedAdapterDelegate <NSObject>

/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoadForAdapter:(MobiFeedAdapter *)adapter views:(NSArray<__kindof MobiNativeExpressFeedView *> *)views;

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoadForAdapter:(MobiFeedAdapter *)adapter error:(NSError *)error;

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)nativeExpressAdDidExpireForAdapter:(MobiFeedAdapter *)adapter;

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackgroundForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdViewForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVCForAdapter:(MobiNativeExpressFeedView *)nativeExpressAdView;

@end
