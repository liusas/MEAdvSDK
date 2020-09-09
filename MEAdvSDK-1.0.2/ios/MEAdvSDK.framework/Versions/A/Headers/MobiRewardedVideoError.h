//
//  MobiRewardedVideoError.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import <Foundation/Foundation.h>

typedef enum {
    MobiRewardedVideoAdErrorUnknown = -1, /*未知错误*/

    MobiRewardedVideoAdErrorTimeout = -1000, /*超时错误*/
    MobiRewardedVideoAdErrorAdUnitWarmingUp = -1001, /*广告单元正在预热,请稍后重试*/
    MobiRewardedVideoAdErrorNoAdsAvailable = -1100, /*没有有效广告*/
    MobiRewardedVideoAdErrorInvalidCustomEvent = -1200, /*无效的激励视频执行工具*/
    MobiRewardedVideoAdErrorMismatchingAdTypes = -1300, /*广告类型不匹配*/
    MobiRewardedVideoAdErrorAdAlreadyPlayed = -1400, /*激励视频正在播放*/
    MobiRewardedVideoAdErrorNoAdReady = -1401, /*广告没有准备好,无法播放*/
    MobiRewardedVideoAdErrorInvalidPosid = -1500, /*无效的广告位id*/
    MobiRewardedVideoAdErrorInvalidReward = -1600, /*无效的奖励*/
    MobiRewardedVideoAdErrorNoRewardSelected = -1601, /*没有奖励*/
} MobiRewardedVideoErrorCode;

/// extern关键字用来声明一个变量,表示定义在别的地方,不在这里
extern NSString * const MobiRewardedVideoAdsSDKDomain;

@interface NSError (MobiRewardVideo)

+ (NSError *)rewardVideoErrorWithCode:(MobiRewardedVideoErrorCode)code localizedDescription:(NSString *)description;

@end
