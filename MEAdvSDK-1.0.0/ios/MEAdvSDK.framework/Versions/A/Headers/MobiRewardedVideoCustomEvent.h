//
//  MobiRewardedVideoCustomEvent.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/10.
//

#import <Foundation/Foundation.h>

@protocol MobiRewardedVideoCustomEventDelegate;
@class MobiRewardedVideoReward;
@class MobiConfig;

@protocol MobiRewardedVideoCustomEvent <NSObject>

/**
 * 适用于custom event的键值对,mopub本意是,custom event可以由SDK外部去实现,这个字段用于传递一些custom evnet需要,而SDK中无法传递的字段,以localExtras传递,暂时保留这个字段,以便日后进行精细化拆分
 */
@property (nonatomic, copy) NSDictionary * localExtras;

@property (nonatomic, weak) id<MobiRewardedVideoCustomEventDelegate> delegate;
/// 当SDK请求拉取广告时,会调用此方法
/// 基类MobiRewardedVideoCustomEvent实现了MobiRewardedVideoCustomEvent接口
/// 这是必须实现的方法,基类不做任何事情,子类需要重写这个方法通过某种方式加载一个激励视频广告
/// Mopub本意是让这个框架适配聚合广告平台,因此一些mediationSettings我们不需要去考虑,因为自有SDK我们已经知道要传递什么参数
/// @param info custom event类请求广告需要传递的数据
/// @param adMarkup 广告标记,可为nil
- (void)requestRewardedVideoWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup;

/// 上层调用`presentRewardedVideoFromViewController`展示广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable;

/// 展示激励视频广告
/// 一般在广告加载成功后调用,需要重写这个类,实现弹出激励视频广告
/// 注意,如果重写的`enableAutomaticImpressionAndClickTracking`方法返回NO,
/// 那么需要自行实现`trackImpression`方法进行数据上报,否则不用处理,交由上层的adapter处理即可
/// @param viewController 弹出激励视频广告的类
- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController;

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

@interface MobiRewardedVideoCustomEvent : NSObject<MobiRewardedVideoCustomEvent>

@property (nonatomic, copy) NSDictionary * localExtras;
@property (nonatomic, weak) id<MobiRewardedVideoCustomEventDelegate> delegate;

@end

@protocol MobiRewardedVideoCustomEventDelegate <NSObject>

/// 广告加载成功后立即调用此方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
/// 注意:加载成功后,这个方法必须实现,不执行此方法会终断SDK处理流程,导致广告展示错误
- (void)rewardedVideoDidLoadAdForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;
/// 广告资源缓存成功调用此方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoAdVideoDidLoadForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 广告加载失败后立即调用此方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
/// 注意:加载成功后,这个方法必须实现,不执行此方法会终断SDK处理流程,导致广告展示错误
- (void)rewardedVideoDidFailToLoadAdForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent error:(NSError *)error;

/// 当一个已经加载成功的广告不再有效时,调用此方法,告知上层,抛弃这个广告并重新加载一个广告
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoDidExpireForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 当视图播放一个激励视频,但激励视频并没有播放成功时,调用此方法
/// 另一个调用此方法的原因是,要播放视频时,该视频失效了
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
/// @param error 错误信息
- (void)rewardedVideoDidFailToPlayForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent error:(NSError *)error;

/// 视频即将展现时调用此方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoWillAppearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 视频已经展现时调用此方法,若你无法得知这个时机,则调用完willAppear后立即调用didAppear方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoDidAppearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 视频即将关闭时调用此方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoWillDisappearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 视频已经关闭时调用此方法,若你无法得知这个时机,则调用完willDisappear后立即调用didDisappear方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoDidDisappearForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 当激励视频广告引起用户离开应用时,调用此方法
/// 比如用户点击了广告后,被重定向到了App Store或Safari
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoWillLeaveApplicationForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 当用户点击了激励视频广告时,回调此方法,若手动管理展现和点击上报,则要保证这个方法只能回调一次
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (void)rewardedVideoDidReceiveTapEventForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 当观看激励视频应该给用户奖励时,回调此方法
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
/// @param reward 要把MobiRewardedVideoReward中的货币类型和数量给用户
/// 若货币类型不属于这个广告平台,则设置currency类型为kMPRewardedVideoRewardCurrencyTypeUnspecified
- (void)rewardedVideoShouldRewardUserForCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent reward:(MobiRewardedVideoReward *)reward;

/// 调用这个代理方法,从上层获取userid用户唯一标识
/// @param customEvent 返回子类的`self`,便于上层处理计时等操作
- (NSString *)customerIdForRewardedVideoCustomEvent:(id<MobiRewardedVideoCustomEvent>)customEvent;

/// 调用此方法上报广告展示事件
/// 调用此代理的前提是`enableAutomaticImpressionAndClickTracking`返回NO,及不允许上层自动上报,一般没必要这样设置
- (void)trackImpression;

/// 调用此方法上报广告点击事件
/// 调用此代理的前提是`enableAutomaticImpressionAndClickTracking`返回NO,及不允许上层自动上报,一般没必要这样设置
- (void)trackClick;

/// 上报视频进度
- (void)trackProgressImpressionWithUrlArr:(NSArray *)urls;

@end

