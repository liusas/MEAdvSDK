//
//  MobiRewardedVideoAdManager.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import <Foundation/Foundation.h>
#import "MobiAdTargeting.h"

NS_ASSUME_NONNULL_BEGIN
@class MobiRewardedVideoReward;
@class MPImpressionData;
@protocol MobiRewardedVideoAdManagerDelegate;

@interface MobiRewardedVideoAdManager : NSObject

@property (nonatomic, weak) id<MobiRewardedVideoAdManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *posid;
/// 用户唯一标识
@property (nonatomic, copy) NSString *userId;
/// 数组中存有从配置中拉取下来的有效广告对象
@property (nonatomic, readonly) NSArray *availableRewards;
/// 从availableRewards选中的给用户的奖励,默认是选择数组的第一个奖励
@property (nonatomic, readonly) MobiRewardedVideoReward *selectedReward;
@property (nonatomic, strong) MobiAdTargeting *targeting;

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiRewardedVideoAdManagerDelegate>)delegate;

/**
 * 加载激励视频广告
 * @param userId 用户的唯一标识
 * @param targeting 精准广告投放的一些参数,可为空
 */
- (void)loadRewardedVideoAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting;

/**
 * 判断这个ad manager下的广告是否是有效且可以直接展示的
 */
- (BOOL)hasAdAvailable;

/**
 * 弹出激励视频广告
 *
 * @param viewController 用来present出视频控制器的控制器
 * @param reward 从`availableRewards`中选择的奖励,在用户完成视频观看时给予用户
 */
- (void)presentRewardedVideoAdFromViewController:(UIViewController *)viewController withReward:(MobiRewardedVideoReward *)reward;

/**
 * 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
 * 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
 */
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiRewardedVideoAdManagerDelegate <NSObject>

- (void)rewardedVideoDidLoadForAdManager:(MobiRewardedVideoAdManager *)manager;
/// 广告资源缓存成功调用此方法
- (void)rewardedVideoAdVideoDidLoadForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoDidFailToLoadForAdManager:(MobiRewardedVideoAdManager *)manager error:(NSError *)error;
- (void)rewardedVideoDidExpireForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoDidFailToPlayForAdManager:(MobiRewardedVideoAdManager *)manager error:(NSError *)error;
- (void)rewardedVideoWillAppearForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoDidAppearForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoWillDisappearForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoDidDisappearForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoDidReceiveTapEventForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoAdManager:(MobiRewardedVideoAdManager *)manager didReceiveImpressionEventWithImpressionData:(MPImpressionData *)impressionData;
- (void)rewardedVideoWillLeaveApplicationForAdManager:(MobiRewardedVideoAdManager *)manager;
- (void)rewardedVideoShouldRewardUserForAdManager:(MobiRewardedVideoAdManager *)manager reward:(MobiRewardedVideoReward *)reward;

@end

NS_ASSUME_NONNULL_END
