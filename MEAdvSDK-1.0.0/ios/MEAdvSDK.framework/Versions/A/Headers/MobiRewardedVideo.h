//
//  MobiRewardedVideo.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import <Foundation/Foundation.h>

@protocol MobiRewardedVideoDelegate;
@class MobiRewardedVideoReward;
@class MobiRewardedVideoModel;

@interface MobiRewardedVideo : NSObject

@property (nonatomic, copy) NSString *posid;
@property (nonatomic, strong) MobiRewardedVideoModel *rewardedVideoModel;

/// 设置用来接收posid对应的激励视频回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiRewardedVideoDelegate>)delegate forPosid:(NSString *)posid;

/// 从有效的posid中删除对应的接收激励视频回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiRewardedVideoDelegate>)delegate;

/// 删除posid对应的delegate
/// @param posid 广告位id
+ (void)removeDelegateForPosid:(NSString *)posid;

/// 加载激励视频广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid, reward, rewardAmount等),可为nil
+ (void)loadRewardedVideoAdWithPosid:(NSString *)posid rewardedVideoModel:(MobiRewardedVideoModel *)model;

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid;

/// 返回posid对应的有效奖励数组
/// @param posid 广告位id
+ (NSArray *)availableRewardsForPosid:(NSString *)posid;

/// 返回看完激励视频后给用户的奖励,默认情况下,返回的是`availableRewardsForPosid`的第一个元素
/// @param posid 广告位id
+ (MobiRewardedVideoReward *)selectedRewardForPosid:(NSString *)posid;

/// 播放一个激励视频广告
/// @param posid 激励视频广告的posid
/// @param viewController 用来present出视频广告的控制器
/// @param reward 看完广告给的奖励,从`availableRewardsForPosid`中选出的一种奖励,可为nil
/// 注意:在调用此方法之前,需要先调用`hasAdAvailableForPosid`方法判断视频广告是否有效,
+ (void)showRewardedVideoAdForPosid:(NSString *)posid fromViewController:(UIViewController *)viewController withReward:(MobiRewardedVideoReward *)reward;

@end

@protocol MobiRewardedVideoDelegate <NSObject>

@optional

/**
 * 激励视频资源加载完成回调此方法
 *
 */
- (void)rewardedVideoAdDidLoad:(MobiRewardedVideo *)rewardedVideo;

/**
 * 广告资源缓存成功调用此方法
 * 建议在此方法回调后执行播放视频操作
 */
- (void)rewardedVideoAdVideoDidLoad:(MobiRewardedVideo *)rewardedVideo;

/**
 * 激励视频资源加载失败回调此方法
 * @param error NSError类型的错误信息
 */
- (void)rewardedVideoAdDidFailToLoad:(MobiRewardedVideo *)rewardedVideo error:(NSError *)error;

/**
 * 当一个posid加载完的激励视频资源失效时(过期),回调此方法
 * 这也是为什么需要在调用`showRewardedVideoAdForPosid`之前调用`hasAdAvailableForPosid`判断一下广告资源是否有效
 */
- (void)rewardedVideoAdDidExpire:(MobiRewardedVideo *)rewardedVideo;

/**
 * 当试图播放激励视频资源时出现错误时,调用此方法
 * @param error NSError类型的错误信息,提示为什么播放错误
 */
- (void)rewardedVideoAdDidFailToPlay:(MobiRewardedVideo *)rewardedVideo error:(NSError *)error;

/**
 * 当激励视频广告即将显示时,调用此方法
 *
 */
- (void)rewardedVideoAdWillAppear:(MobiRewardedVideo *)rewardedVideo;

/**
 * 当激励视频广告已经显示时,调用此方法
 *
 */
- (void)rewardedVideoAdDidAppear:(MobiRewardedVideo *)rewardedVideo;

/**
 * 当激励视频广告即将关闭时,调用此方法
 *
 */
- (void)rewardedVideoAdWillDisappear:(MobiRewardedVideo *)rewardedVideo;

/**
 * 当激励视频广告已经关闭时,调用此方法
 *
 */
- (void)rewardedVideoAdDidDisappear:(MobiRewardedVideo *)rewardedVideo;

/**
 * 当用户点击了激励视频广告时,回调此方法
 *
 */
- (void)rewardedVideoAdDidReceiveTapEvent:(MobiRewardedVideo *)rewardedVideo;

/**
 * 当激励视频即将引发用户离开应用时,调用此方法
 *
 */
- (void)rewardedVideoAdWillLeaveApplication:(MobiRewardedVideo *)rewardedVideo;

/**
 * 当激励视频播放到已经满足奖励条件时,会回调此方法,我们可以依次给予用户奖励
 *
 * @param reward 返回给用户的奖励信息
 */
- (void)rewardedVideoAdShouldReward:(MobiRewardedVideo *)rewardedVideo reward:(MobiRewardedVideoReward *)reward;


@end
