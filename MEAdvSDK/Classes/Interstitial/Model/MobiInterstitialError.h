//
//  MobiInterstitialError.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/18.
//

#import <Foundation/Foundation.h>

typedef enum {
    MobiInterstitialAdErrorUnknown = -1, /*未知错误*/

    MobiInterstitialAdErrorTimeout = -1000, /*超时错误*/
    MobiInterstitialAdErrorAdUnitWarmingUp = -1001, /*广告单元正在预热,请稍后重试*/
    MobiInterstitialAdErrorNoAdsAvailable = -1100, /*没有有效广告*/
    MobiInterstitialAdErrorInvalidCustomEvent = -1200, /*无效的信息流执行工具*/
    MobiInterstitialAdErrorMismatchingAdTypes = -1300, /*广告类型不匹配*/
    MobiInterstitialAdErrorAdAlreadyPlayed = -1400, /*激励视频正在播放*/
    MobiInterstitialAdErrorNoAdReady = -1401, /*广告没有准备好,无法播放*/
    MobiInterstitialAdErrorInvalidPosid = -1500, /*无效的广告位id*/
    MobiInterstitialAdErrorInvalidReward = -1600, /*无效的奖励*/
    MobiInterstitialAdErrorNoRewardSelected = -1601, /*没有奖励*/
} MobiInterstitialErrorCode;

/// extern关键字用来声明一个变量,表示定义在别的地方,不在这里
extern NSString * const MobiInterstitialAdsSDKDomain;

