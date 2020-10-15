//
//  MobiFullscreenCustomEvent.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import "MobiFullscreenCustomEvent.h"

@implementation MobiFullscreenCustomEvent

- (void)requestFullscreenVideoWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {}

/// 上层调用`presentFullscreenVideoFromViewController`展示广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable {return NO;}

/// 展示激励视频广告
/// 一般在广告加载成功后调用,需要重写这个类,实现弹出激励视频广告
/// 注意,如果重写的`enableAutomaticImpressionAndClickTracking`方法返回NO,
/// 那么需要自行实现`trackImpression`方法进行数据上报,否则不用处理,交由上层的adapter处理即可
/// @param viewController 弹出激励视频广告的类
- (void)presentFullscreenVideoFromViewController:(UIViewController *)viewController {}

/// 子类重写次方法,决定由谁处理展现和点击上报
/// 默认return YES;由上层adapter处理展现和点击上报,
/// 若return NO;则由子类实现trackImpression和trackClick方法,实现上报,但要保证每个广告只上报一次
- (BOOL)enableAutomaticImpressionAndClickTracking {return YES;}

/// 这个方法存在的意义是聚合广告,因为聚合广告可能会出现两个广告单元用同一个广告平台加载广告
/// 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
/// 当然广告失效后需要回调`[-FullscreenVideoDidExpireForCustomEvent:]([MPFullscreenVideoCustomEventDelegate FullscreenVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
/// 并且我们要重写这个方法,让这个Custom event类能释放掉
/// 默认这个方法不会做任何事情
- (void)handleAdPlayedForCustomEventNetwork {}

/// 在激励视频系统不再需要这个custom event类时,会调用这个方法,目的是让custom event能够成功释放掉,如果能保证custom event不会造成内存泄漏,则这个方法不用重写
- (void)handleCustomEventInvalidated {}

@end
