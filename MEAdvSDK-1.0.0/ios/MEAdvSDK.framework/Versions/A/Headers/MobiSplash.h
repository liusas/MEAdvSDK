//
//  MobiSplash.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import <Foundation/Foundation.h>

@protocol MobiSplashDelegate;
@class MobiSplashModel;

@interface MobiSplash : NSObject

@property (nonatomic, copy) NSString *posid;
@property (nonatomic, strong) MobiSplashModel *splashModel;

/// 设置用来接收posid对应的广告回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiSplashDelegate>)delegate forPosid:(NSString *)posid;

/// 从有效的posid中删除对应的接收广告回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiSplashDelegate>)delegate;

/// 删除posid对应的delegate
/// @param posid 广告位id
+ (void)removeDelegateForPosid:(NSString *)posid;

/// 加载开屏广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid, fetchDelay, backgroundImage等),可为nil
+ (void)loadSplashAdAndShowWithWindow:(UIWindow *)window posid:(NSString *)posid SplashModel:(MobiSplashModel *)model;

/// 加载开屏广告
/// 发起拉取广告请求,并将获取的广告以半屏形式展示在传入的Window的上半部，剩余部分展示传入的bottomView       请注意1.bottomView需设置好宽高，所占的空间不能过大，并保证高度不超过屏幕高度的 25%。2.Splash广告只支持竖屏
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid, fetchDelay, backgroundImage等),可为nil
/// @param bottomView 自定义底部View，可以在此View中设置应用Logo
+ (void)loadSplashAdAndShowWithWindow:(UIWindow *)window posid:(NSString *)posid SplashModel:(MobiSplashModel *)model withBottomView:(UIView *)bottomView;

/// 停止开屏广告
/// @param posid 广告位id
+ (void)stopSplashAdWithPosid:(NSString *)posid;

/// 判断posid对应的开屏广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid;

/// 预加载闪屏广告接口
/// @param posid 广告位ID
+ (void)preloadSplashOrderWithPosid:(NSString *)posid;

@end

@protocol MobiSplashDelegate <NSObject>

@optional
/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreen:(MobiSplash *)splashAd;

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoad:(MobiSplash *)splashAd;

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresent:(MobiSplash *)splashAd withError:(NSError *)error;

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackground:(MobiSplash *)splashAd;

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposured:(MobiSplash *)splashAd;

/**
 *  开屏广告点击回调
 */
- (void)splashAdClicked:(MobiSplash *)splashAd;

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosed:(MobiSplash *)splashAd;

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosed:(MobiSplash *)splashAd;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpire:(MobiSplash *)splashAd;

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModal:(MobiSplash *)splashAd;

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModal:(MobiSplash *)splashAd;

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModal:(MobiSplash *)splashAd;

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModal:(MobiSplash *)splashAd;

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAd:(MobiSplash *)splashAd lifeTime:(NSUInteger)time;

@end
