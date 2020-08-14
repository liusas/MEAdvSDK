//
//  MobiFeed.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "MobiGlobal.h"

@protocol MobiFeedDelegate;
@class MobiNativeExpressFeedView;
@class MobiFeedModel;

@interface MobiFeed : NSObject

@property (nonatomic, copy) NSString *posid;
@property (nonatomic, strong) MobiFeedModel *feedModel;

/// 设置用来接收posid对应的信息流回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiFeedDelegate>)delegate forPosid:(NSString *)posid;

/// 从有效的posid中删除对应的接收信息流回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiFeedDelegate>)delegate;

/// 删除posid对应的delegate
/// @param posid 广告位id
+ (void)removeDelegateForPosid:(NSString *)posid;

/// 加载信息流广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid,count,videoAutoPlayOnWWAN,videoMuted等),可为nil
+ (void)loadFeedAdWithPosid:(NSString *)posid feedModel:(MobiFeedModel *)model;

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid;

@end

@protocol MobiFeedDelegate <NSObject>

@optional
/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoad:(MobiFeed *)nativeExpressAd views:(NSArray<__kindof MobiNativeExpressFeedView *> *)views;

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoad:(MobiFeed *)nativeExpressAd error:(NSError *)error;

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccess:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFail:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposure:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClicked:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosed:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 当一个posid加载完的广告资源失效时(过期),回调此方法
 */
- (void)nativeExpressAdDidExpire:(MobiFeed *)nativeExpressAd;

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreen:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreen:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreen:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreen:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackground:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdView:(MobiNativeExpressFeedView *)nativeExpressAdView playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVC:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVC:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVC:(MobiNativeExpressFeedView *)nativeExpressAdView;

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVC:(MobiNativeExpressFeedView *)nativeExpressAdView;

@end
