//
//  MobiFullscreenError.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    MobiFullscreenVideoAdErrorUnknown = -1, /*未知错误*/

    MobiFullscreenVideoAdErrorTimeout = -1000, /*超时错误*/
    MobiFullscreenVideoAdErrorAdUnitWarmingUp = -1001, /*广告单元正在预热,请稍后重试*/
    MobiFullscreenVideoAdErrorNoAppid = -1002, /*广告的 appid 为空*/
    MobiFullscreenVideoAdErrorNoAdsAvailable = -1100, /*没有有效广告*/
    MobiFullscreenVideoAdErrorInvalidCustomEvent = -1200, /*无效的激励视频执行工具*/
    MobiFullscreenVideoAdErrorMismatchingAdTypes = -1300, /*广告类型不匹配*/
    MobiFullscreenVideoAdErrorAdAlreadyPlayed = -1400, /*激励视频正在播放*/
    MobiFullscreenVideoAdErrorNoAdReady = -1401, /*广告没有准备好,无法播放*/
    MobiFullscreenVideoAdErrorInvalidPosid = -1500, /*无效的广告位id*/
    MobiFullscreenVideoAdErrorInvalidReward = -1600, /*无效的奖励*/
    MobiFullscreenVideoAdErrorNoRewardSelected = -1601, /*没有奖励*/
} MobiFullscreenVideoErrorCode;

/// extern关键字用来声明一个变量,表示定义在别的地方,不在这里
extern NSString * const MobiFullscreenVideoAdsSDKDomain;

@interface NSError (MobiFullscreenVideo)

+ (NSError *)fullscreenVideoErrorWithCode:(MobiFullscreenVideoErrorCode)code localizedDescription:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
