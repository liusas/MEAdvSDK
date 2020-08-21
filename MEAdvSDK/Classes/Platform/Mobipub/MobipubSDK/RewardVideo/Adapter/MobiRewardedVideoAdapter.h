//
//  MobiRewardedVideoAdapter.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/10.
//

#import <Foundation/Foundation.h>
#import "MobiPrivateRewardedVideoCustomEventDelegate.h"

@class MobiConfig;
@class MobiAdTargeting;
@class MobiRewardedVideoReward;

@protocol MobiRewardedVideoAdapterDelegate;

/// 通过adapter去选择一个custom event类去执行广告的加载和展示
@interface MobiRewardedVideoAdapter : NSObject<MobiPrivateRewardedVideoCustomEventDelegate>

@property (nonatomic, weak) id<MobiRewardedVideoAdapterDelegate> delegate;

- (instancetype)initWithDelegate:(id<MobiRewardedVideoAdapterDelegate>)delegate;

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
- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController;

/**
* 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
* 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
*/
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiRewardedVideoAdapterDelegate <NSObject>

- (void)rewardedVideoDidLoadForAdapter:(MobiRewardedVideoAdapter *)adapter;
/// 广告资源缓存成功调用此方法
- (void)rewardedVideoAdVideoDidLoadForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoDidFailToLoadForAdapter:(MobiRewardedVideoAdapter *)adapter error:(NSError *)error;
- (void)rewardedVideoDidExpireForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoDidFailToPlayForAdapter:(MobiRewardedVideoAdapter *)adapter error:(NSError *)error;
- (void)rewardedVideoWillAppearForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoDidAppearForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoWillDisappearForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoDidDisappearForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoDidReceiveTapEventForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoDidReceiveImpressionEventForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoWillLeaveApplicationForAdapter:(MobiRewardedVideoAdapter *)adapter;
- (void)rewardedVideoShouldRewardUserForAdapter:(MobiRewardedVideoAdapter *)adapter reward:(MobiRewardedVideoReward *)reward;

@optional
- (NSString *)rewardedVideoAdUnitId;
- (NSString *)rewardedVideoCustomerId;
- (MobiConfig *)configuration;

@end
