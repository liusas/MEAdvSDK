//
//  MobiInterstitialCustomEvent.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/18.
//

#import "MobiInterstitialCustomEvent.h"

@implementation MobiInterstitialCustomEvent

/// 当SDK请求拉取广告时,会调用此方法
/// 基类MobiSplashCustomEvent实现了MobiInterstitialCustomEvent接口
/// 这是必须实现的方法,基类不做任何事情,子类需要重写这个方法通过某种方式加载一个激励视频广告
/// Mopub本意是让这个框架适配聚合广告平台,因此一些mediationSettings我们不需要去考虑,因为自有SDK我们已经知道要传递什么参数
/// @param info custom event类请求广告需要传递的数据
/// @param adMarkup 广告标记,可为nil
- (void)requestInterstitialWithCustomEventInfo:(MobiConfig *)configuration adMarkup:(NSString *)adMarkup {
    
}

/// 上层展示广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable {
    return NO;
}

/// 弹出广告
/// @param rootViewController 用来弹出信息流广告的根视图
- (void)showInterstitialAdFromViewController:(UIViewController *)rootViewController {
    
}

/// 子类重写次方法,决定由谁处理展现和点击上报
/// 默认return YES;由上层adapter处理展现和点击上报,
/// 若return NO;则由子类实现trackImpression和trackClick方法,实现上报,但要保证每个广告只上报一次
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return YES;
}

/// 这个方法存在的意义是聚合广告,因为聚合广告可能会出现两个广告单元用同一个广告平台加载广告
/// 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
/// 当然广告失效后需要回调`[-splashDidExpireForCustomEvent:]`方法告诉用户这个广告已不再有效
/// 并且我们要重写这个方法,让这个Custom event类能释放掉
/// 默认这个方法不会做任何事情
- (void)handleAdPlayedForCustomEventNetwork {
    
}

/// 在广告系统不再需要这个custom event类时,会调用这个方法,目的是让custom event能够成功释放掉,如果能保证custom event不会造成内存泄漏,则这个方法不用重写
- (void)handleCustomEventInvalidated {
    
}

@end
