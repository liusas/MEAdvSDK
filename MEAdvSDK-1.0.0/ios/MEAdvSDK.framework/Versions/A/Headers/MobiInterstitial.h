//
//  MobiInterstitial.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/18.
//

#import <Foundation/Foundation.h>
#import "MobiGlobal.h"

@protocol MobiInterstitialDelegate;
@class MobiInterstitialModel;

@interface MobiInterstitial : NSObject

@property (nonatomic, copy) NSString *posid;
@property (nonatomic, strong) MobiInterstitialModel *interstitialModel;

/// 设置用来接收posid对应的信息流回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiInterstitialDelegate>)delegate forPosid:(NSString *)posid;

/// 从有效的posid中删除对应的接收信息流回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiInterstitialDelegate>)delegate;

/// 删除posid对应的delegate
/// @param posid 广告位id
+ (void)removeDelegateForPosid:(NSString *)posid;

/// 加载信息流广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid,count,videoAutoPlayOnWWAN,videoMuted等),可为nil
+ (void)loadInterstitialAdWithPosid:(NSString *)posid interstitialModel:(MobiInterstitialModel *)model;

/// 弹出广告
/// @param rootViewController 用来弹出信息流广告的根视图
+ (void)showInterstitialAdFromViewController:(UIViewController *)viewController posid:(NSString *)posid;

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid;


@end

@protocol MobiInterstitialDelegate <NSObject>

@optional

/**
 *  插屏2.0广告预加载成功回调
 *  当接收服务器返回的广告数据成功且预加载后调用该函数
 */
- (void)unifiedInterstitialSuccessToLoadAd:(MobiInterstitial *)unifiedInterstitial;

/**
 *  插屏2.0广告预加载失败回调
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedInterstitialFailToLoadAd:(MobiInterstitial *)unifiedInterstitial error:(NSError *)error;

/**
 *  插屏2.0广告将要展示回调
 *  插屏2.0广告即将展示回调该函数
 */
- (void)unifiedInterstitialWillPresentScreen:(MobiInterstitial *)unifiedInterstitial;

/**
 *  插屏2.0广告视图展示成功回调
 *  插屏2.0广告展示成功回调该函数
 */
- (void)unifiedInterstitialDidPresentScreen:(MobiInterstitial *)unifiedInterstitial;

/**
 *  插屏2.0广告视图展示失败回调
 *  插屏2.0广告展示失败回调该函数
 */
- (void)unifiedInterstitialFailToPresent:(MobiInterstitial *)unifiedInterstitial error:(NSError *)error;

/**
 *  插屏2.0广告展示结束回调
 *  插屏2.0广告展示结束回调该函数
 */
- (void)unifiedInterstitialDidDismissScreen:(MobiInterstitial *)unifiedInterstitial;

/**
 *  当点击下载应用时会调用系统程序打开其它App或者Appstore时回调
 */
- (void)unifiedInterstitialWillLeaveApplication:(MobiInterstitial *)unifiedInterstitial;

/**
 *  插屏2.0广告曝光回调
 */
- (void)unifiedInterstitialWillExposure:(MobiInterstitial *)unifiedInterstitial;

/**
 *  插屏2.0广告点击回调
 */
- (void)unifiedInterstitialClicked:(MobiInterstitial *)unifiedInterstitial;

/**
 *  点击插屏2.0广告以后即将弹出全屏广告页
 */
- (void)unifiedInterstitialAdWillPresentFullScreenModal:(MobiInterstitial *)unifiedInterstitial;

/**
 *  点击插屏2.0广告以后弹出全屏广告页
 */
- (void)unifiedInterstitialAdDidPresentFullScreenModal:(MobiInterstitial *)unifiedInterstitial;

/**
 *  全屏广告页将要关闭
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModal:(MobiInterstitial *)unifiedInterstitial;

/**
 *  全屏广告页被关闭
 */
- (void)unifiedInterstitialAdDidDismissFullScreenModal:(MobiInterstitial *)unifiedInterstitial;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)unifiedInterstitialAdDidExpire:(MobiInterstitial *)unifiedInterstitial;

/**
 * 插屏2.0视频广告 player 播放状态更新回调
 */
- (void)unifiedInterstitialAd:(MobiInterstitial *)unifiedInterstitial playerStatusChanged:(MobiMediaPlayerStatus)status;

/**
 * 插屏2.0视频广告详情页 WillPresent 回调
 */
- (void)unifiedInterstitialAdViewWillPresentVideoVC:(MobiInterstitial *)unifiedInterstitial;

/**
 * 插屏2.0视频广告详情页 DidPresent 回调
 */
- (void)unifiedInterstitialAdViewDidPresentVideoVC:(MobiInterstitial *)unifiedInterstitial;

/**
 * 插屏2.0视频广告详情页 WillDismiss 回调
 */
- (void)unifiedInterstitialAdViewWillDismissVideoVC:(MobiInterstitial *)unifiedInterstitial;

/**
 * 插屏2.0视频广告详情页 DidDismiss 回调
 */
- (void)unifiedInterstitialAdViewDidDismissVideoVC:(MobiInterstitial *)unifiedInterstitial;

@end
