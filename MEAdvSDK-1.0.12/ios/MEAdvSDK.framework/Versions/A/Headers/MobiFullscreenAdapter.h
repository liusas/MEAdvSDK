//
//  MobiFullscreenAdapter.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "MobiPrivateFullscreenVideoCustomEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class MobiConfig;
@class MobiAdTargeting;

@protocol MobiFullscreenVideoAdapterDelegate;

/// 通过adapter去选择一个custom event类去执行广告的加载和展示
@interface MobiFullscreenAdapter : NSObject<MobiPrivateFullscreenVideoCustomEventDelegate>

@property (nonatomic, weak) id<MobiFullscreenVideoAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<MobiFullscreenVideoAdapterDelegate>)delegate;

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
 * 播放一个激励视频
 *
 * @param viewController 用来弹出播放器控制器的控制器
 */
- (void)presentFullscreenVideoFromViewController:(UIViewController *)viewController;

/**
* 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
* 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
*/
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiFullscreenVideoAdapterDelegate <NSObject>

- (void)fullscreenVideoDidLoadForAdAdapter:(MobiFullscreenAdapter *)adapter;
/// 广告资源缓存成功调用此方法
- (void)fullscreenVideoAdVideoDidLoadForAdAdapter:(MobiFullscreenAdapter *)adapter;
- (void)fullscreenVideoDidFailToLoadForAdAdapter:(MobiFullscreenAdapter *)adapter error:(NSError *)error;
- (void)fullscreenVideoDidExpireForAdAdapter:(MobiFullscreenAdapter *)adapter;
- (void)fullscreenVideoDidFailToPlayForAdAdapter:(MobiFullscreenAdapter *)adapter error:(NSError *)error;

- (void)fullscreenVideoAdViewRenderFailForAdAdapter:(MobiFullscreenAdapter *)adapter error:(NSError *_Nullable)error;
- (void)fullscreenVideoWillAppearForAdAdapter:(MobiFullscreenAdapter *)adapter;
- (void)fullscreenVideoDidAppearForAdAdapter:(MobiFullscreenAdapter *)adapter;
- (void)fullscreenVideoWillDisappearForAdAdapter:(MobiFullscreenAdapter *)adapter;
- (void)fullscreenVideoDidDisappearForAdAdapter:(MobiFullscreenAdapter *)adapter;

- (void)fullscreenVideoAdDidPlayFinishForAdAdapter:(MobiFullscreenAdapter *)adapter didFailWithError:(NSError *)error;
- (void)fullscreenVideoDidReceiveTapEventForAdAdapter:(MobiFullscreenAdapter *)adapter;
//- (void)fullscreenVideoAdManager:(MobiFullscreenAdManager *)manager didReceiveImpressionEventWithImpressionData:(MPImpressionData *)impressionData;
- (void)fullscreenVideoWillLeaveApplicationForAdAdapter:(MobiFullscreenAdapter *)adapter;

/**
 This method is called when the user clicked skip button.
 */
- (void)fullscreenVideoAdDidClickSkip:(MobiFullscreenAdapter *)adapter;

@optional
- (NSString *)fullscreenVideoAdUnitId;
- (NSString *)fullscreenVideoCustomerId;
- (MobiConfig *)configuration;

@end

NS_ASSUME_NONNULL_END
