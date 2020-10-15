//
//  MobiSplashError.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import <Foundation/Foundation.h>

typedef enum {
    MobiSplashAdErrorUnknown = -1, /*未知错误*/

    MobiSplashAdErrorTimeout = -1000, /*超时错误*/
    MobiSplashAdErrorAdUnitWarmingUp = -1001, /*广告单元正在预热,请稍后重试*/
    MobiSplashAdErrorNoAdsAvailable = -1100, /*没有有效广告*/
    MobiSplashAdErrorInvalidCustomEvent = -1200, /*无效的激励视频执行工具*/
    MobiSplashAdErrorMismatchingAdTypes = -1300, /*广告类型不匹配*/
    MobiSplashAdErrorAdAlreadyPlayed = -1400, /*激励视频正在播放*/
    MobiSplashAdErrorNoAdReady = -1401, /*广告没有准备好,无法播放*/
    MobiSplashAdErrorInvalidPosid = -1500, /*无效的广告位id*/
    MobiSplashAdErrorInvalidReward = -1600, /*无效的奖励*/
    MobiSplashAdErrorNoRewardSelected = -1601, /*没有奖励*/
} MobiSplashErrorCode;

/// extern关键字用来声明一个变量,表示定义在别的地方,不在这里
extern NSString * const MobiSplashAdsSDKDomain;

@interface NSError (MobiSplash)

+ (NSError *)splashErrorWithCode:(MobiSplashErrorCode)code localizedDescription:(NSString *)description;

@end
