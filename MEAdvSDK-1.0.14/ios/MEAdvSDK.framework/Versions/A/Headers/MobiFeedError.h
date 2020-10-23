//
//  MobiFeedError.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>

typedef enum {
    MobiFeedAdErrorUnknown = -1, /*未知错误*/

    MobiFeedAdErrorTimeout = -1000, /*超时错误*/
    MobiFeedAdErrorAdUnitWarmingUp = -1001, /*广告单元正在预热,请稍后重试*/
    MobiFeedAdErrorNoAdsAvailable = -1100, /*没有有效广告*/
    MobiFeedAdErrorInvalidCustomEvent = -1200, /*无效的信息流执行工具*/
    MobiFeedAdErrorMismatchingAdTypes = -1300, /*广告类型不匹配*/
    MobiFeedAdErrorAdAlreadyPlayed = -1400, /*激励视频正在播放*/
    MobiFeedAdErrorNoAdReady = -1401, /*广告没有准备好,无法播放*/
    MobiFeedAdErrorInvalidPosid = -1500, /*无效的广告位id*/
    MobiFeedAdErrorInvalidReward = -1600, /*无效的奖励*/
    MobiFeedAdErrorNoRewardSelected = -1601, /*没有奖励*/
} MobiFeedErrorCode;

/// extern关键字用来声明一个变量,表示定义在别的地方,不在这里
extern NSString * const MobiFeedAdsSDKDomain;

@interface NSError (MobiFeed)

+ (NSError *)feedErrorWithCode:(MobiFeedErrorCode)code localizedDescription:(NSString *)description;

@end
