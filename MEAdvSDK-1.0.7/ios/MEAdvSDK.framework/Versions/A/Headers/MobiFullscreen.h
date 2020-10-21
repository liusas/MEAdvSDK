//
//  MobiFullscreen.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import <Foundation/Foundation.h>

@protocol MobiFullscreenVideoDelegate;
@class MobiFullscreenModel;

@interface MobiFullscreen : NSObject

@property (nonatomic, copy) NSString *posid;
@property (nonatomic, strong) MobiFullscreenModel *fullscreenModel;

/// 设置用来接收posid对应的激励视频回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiFullscreenVideoDelegate>)delegate forPosid:(NSString *)posid;

/// 从有效的posid中删除对应的接收激励视频回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiFullscreenVideoDelegate>)delegate;

/// 删除posid对应的delegate
/// @param posid 广告位id
+ (void)removeDelegateForPosid:(NSString *)posid;

/// 加载激励视频广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid, reward, rewardAmount等),可为nil
+ (void)loadFullscreenVideoAdWithPosid:(NSString *)posid fullscreenVideoModel:(MobiFullscreenModel *)model;

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid;


/// 播放一个激励视频广告
/// @param posid 激励视频广告的posid
/// @param viewController 用来present出视频广告的控制器
/// 注意:在调用此方法之前,需要先调用`hasAdAvailableForPosid`方法判断视频广告是否有效,
+ (void)showFullscreenVideoAdForPosid:(NSString *)posid fromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_BEGIN

@protocol MobiFullscreenVideoDelegate <NSObject>

@optional

/**
 * 激励视频资源加载完成回调此方法
 *
 */
- (void)fullscreenVideoAdDidLoad:(MobiFullscreen *)fullscreenVideo;

/**
 * 广告资源缓存成功调用此方法
 * 建议在此方法回调后执行播放视频操作
 */
- (void)fullscreenVideoAdVideoDidLoad:(MobiFullscreen *)fullscreenVideo;

/**
 * 激励视频资源加载失败回调此方法
 * @param error NSError类型的错误信息
 */
- (void)fullscreenVideoAdDidFailToLoad:(MobiFullscreen *)fullscreenVideo error:(NSError *)error;

/**
 * 当一个posid加载完的激励视频资源失效时(过期),回调此方法
 * 这也是为什么需要在调用`showfullscreenVideoAdForPosid`之前调用`hasAdAvailableForPosid`判断一下广告资源是否有效
 */
- (void)fullscreenVideoAdDidExpire:(MobiFullscreen *)fullscreenVideo;

/**
 * 激励视频渲染失败,回调此方法
 */
- (void)fullscreenVideoAdViewRenderFail:(MobiFullscreen *)fullscreenVideo error:(NSError *_Nullable)error;

/**
 * 当激励视频广告即将显示时,调用此方法
 *
 */
- (void)fullscreenVideoAdWillAppear:(MobiFullscreen *)fullscreenVideo;

/**
 * 当激励视频广告已经显示时,调用此方法
 *
 */
- (void)fullscreenVideoAdDidAppear:(MobiFullscreen *)fullscreenVideo;

/**
 * 激励视频播放完毕的回调,当 error 不为空时,表示播放出现错误
 */
- (void)fullscreenVideoAdDidPlayFinish:(MobiFullscreen *)fullscreenVideo didFailWithError:(NSError *)error;

/**
 * 当激励视频广告即将关闭时,调用此方法
 *
 */
- (void)fullscreenVideoAdWillDisappear:(MobiFullscreen *)fullscreenVideo;

/**
 * 当激励视频广告已经关闭时,调用此方法
 *
 */
- (void)fullscreenVideoAdDidDisappear:(MobiFullscreen *)fullscreenVideo;

/**
 * 当用户点击了激励视频广告时,回调此方法
 *
 */
- (void)fullscreenVideoAdDidReceiveTapEvent:(MobiFullscreen *)fullscreenVideo;

/**
 * 当激励视频即将引发用户离开应用时,调用此方法
 *
 */
- (void)fullscreenVideoAdWillLeaveApplication:(MobiFullscreen *)fullscreenVideo;

/**
 This method is called when the user clicked skip button.
 */
- (void)fullscreenVideoAdDidClickSkip:(MobiFullscreen *)fullscreenVideo;

NS_ASSUME_NONNULL_END

@end
