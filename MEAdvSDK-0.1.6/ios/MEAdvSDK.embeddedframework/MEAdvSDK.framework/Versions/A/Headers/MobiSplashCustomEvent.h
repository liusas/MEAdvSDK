//
//  MobiSplashCustomEvent.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import <Foundation/Foundation.h>

@protocol MobiSplashCustomEventDelegate;
@class MobiConfig;
@protocol MobiSplashCustomEvent <NSObject>

/**
 * 适用于custom event的键值对,mopub本意是,custom event可以由SDK外部去实现,这个字段用于传递一些custom evnet需要,而SDK中无法传递的字段,以localExtras传递,暂时保留这个字段,以便日后进行精细化拆分
 */
@property (nonatomic, copy) NSDictionary * localExtras;

@property (nonatomic, weak) id<MobiSplashCustomEventDelegate> delegate;

@property(nonatomic,assign,readonly) CGPoint clickDownPoint;

@property(nonatomic,assign,readonly) CGPoint clickUpPoint;

/// 当SDK请求拉取广告时,会调用此方法
/// 基类MobiSplashCustomEvent实现了MobiSplashCustomEvent接口
/// 这是必须实现的方法,基类不做任何事情,子类需要重写这个方法通过某种方式加载一个激励视频广告
/// Mopub本意是让这个框架适配聚合广告平台,因此一些mediationSettings我们不需要去考虑,因为自有SDK我们已经知道要传递什么参数
/// @param info custom event类请求广告需要传递的数据
/// @param adMarkup 广告标记,可为nil
- (void)requestSplashWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup;

/// 上层展示广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable;

/// 展示开屏广告
/// 一般在广告加载成功后调用,需要重写这个类,实现弹出激励视频广告
/// 注意,如果重写的`enableAutomaticImpressionAndClickTracking`方法返回NO,
/// 那么需要自行实现`trackImpression`方法进行数据上报,否则不用处理,交由上层的adapter处理即可
/// @param window 弹出激励视频广告的类
- (void)presentSplashFromWindow:(UIWindow *)window;

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

/// 在广告系统不再需要这个custom event类时,会调用这个方法,目的是让custom event能够成功释放掉,如果能保证custom event不会造成内存泄漏,则这个方法不用重写
- (void)handleCustomEventInvalidated;

@end

@interface MobiSplashCustomEvent : NSObject<MobiSplashCustomEvent>

@property (nonatomic, copy) NSDictionary * localExtras;
@property (nonatomic, weak) id<MobiSplashCustomEventDelegate> delegate;

@property(nonatomic,assign,readonly) CGPoint clickDownPoint;

@property(nonatomic,assign,readonly) CGPoint clickUpPoint;

@end

@protocol MobiSplashCustomEventDelegate <NSObject>

/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForCustomEvent:(MobiSplashCustomEvent *)splashAd withError:(NSError *)error;

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpireForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForCustomEvent:(MobiSplashCustomEvent *)splashAd;

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdLifeTime:(NSUInteger)time;

/// 调用这个代理方法,从上层获取userid用户唯一标识
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (NSString *)customerIdForSplashCustomEvent:(id<MobiSplashCustomEvent>)customEvent;

/// 调用此方法上报广告展示事件
/// 调用此代理的前提是`enableAutomaticImpressionAndClickTracking`返回NO,及不允许上层自动上报,一般没必要这样设置
- (void)trackImpression;

/// 调用此方法上报广告点击事件
/// 调用此代理的前提是`enableAutomaticImpressionAndClickTracking`返回NO,及不允许上层自动上报,一般没必要这样设置
- (void)trackClick;

@end
