//
//  MobiFullscreenAdManager.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "MobiAdTargeting.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MobiFullscreenAdManagerDelegate;

@interface MobiFullscreenAdManager : NSObject

@property (nonatomic, weak) id<MobiFullscreenAdManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *posid;
/// 用户唯一标识
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) MobiAdTargeting *targeting;

- (instancetype)initWithPosid:(NSString *)posid delegate:(id<MobiFullscreenAdManagerDelegate>)delegate;

/**
* Returns the custom event class type.
*/
- (Class)customEventClass;

/**
 * 加载激励视频广告
 * @param userId 用户的唯一标识
 * @param targeting 精准广告投放的一些参数,可为空
 */
- (void)loadFullscreenVideoAdWithUserId:(NSString *)userId targeting:(MobiAdTargeting *)targeting;

/**
 * 判断这个ad manager下的广告是否是有效且可以直接展示的
 */
- (BOOL)hasAdAvailable;

/**
 * 弹出激励视频广告
 *
 * @param viewController 用来present出视频控制器的控制器
 */
- (void)presentFullscreenVideoAdFromViewController:(UIViewController *)viewController;

/**
 * 有时 load 广告会是广告平台取得缓存中同一个广告,这是广告可能已经失效,用此方法释放掉失效的广告
 */
- (void)handleAdPlayedForCustomEventNetwork;

@end

@protocol MobiFullscreenAdManagerDelegate <NSObject>

- (void)fullscreenVideoDidLoadForAdManager:(MobiFullscreenAdManager *)manager;
/// 广告资源缓存成功调用此方法
- (void)fullscreenVideoAdVideoDidLoadForAdManager:(MobiFullscreenAdManager *)manager;
- (void)fullscreenVideoDidFailToLoadForAdManager:(MobiFullscreenAdManager *)manager error:(NSError *)error;
- (void)fullscreenVideoDidExpireForAdManager:(MobiFullscreenAdManager *)manager;

- (void)fullscreenVideoAdViewRenderFailForAdManager:(MobiFullscreenAdManager *)manager error:(NSError *_Nullable)error;
- (void)fullscreenVideoWillAppearForAdManager:(MobiFullscreenAdManager *)manager;
- (void)fullscreenVideoDidAppearForAdManager:(MobiFullscreenAdManager *)manager;
- (void)fullscreenVideoWillDisappearForAdManager:(MobiFullscreenAdManager *)manager;
- (void)fullscreenVideoDidDisappearForAdManager:(MobiFullscreenAdManager *)manager;

- (void)fullscreenVideoAdDidPlayFinishForAdManager:(MobiFullscreenAdManager *)manager didFailWithError:(NSError *)error;
- (void)fullscreenVideoDidReceiveTapEventForAdManager:(MobiFullscreenAdManager *)manager;
//- (void)fullscreenVideoAdManager:(MobiFullscreenAdManager *)manager didReceiveImpressionEventWithImpressionData:(MPImpressionData *)impressionData;
- (void)fullscreenVideoWillLeaveApplicationForAdManager:(MobiFullscreenAdManager *)manager;

/**
 This method is called when the user clicked skip button.
 */
- (void)fullscreenVideoAdDidClickSkip:(MobiFullscreenAdManager *)manager;

@end

NS_ASSUME_NONNULL_END
