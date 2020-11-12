//
//  MobiDrawViewError.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>

typedef enum {
    MobiDrawViewAdErrorUnknown = -1, /*未知错误*/

    MobiDrawViewAdErrorTimeout = -1000, /*超时错误*/
    MobiDrawViewAdErrorAdUnitWarmingUp = -1001, /*广告单元正在预热,请稍后重试*/
    MobiDrawViewAdErrorNoAdsAvailable = -1100, /*没有有效广告*/
    MobiDrawViewAdErrorInvalidCustomEvent = -1200, /*无效的信息流执行工具*/
    MobiDrawViewAdErrorMismatchingAdTypes = -1300, /*广告类型不匹配*/
    MobiDrawViewAdErrorNoRootVC = -1400, /*没有设置根视图*/
    MobiDrawViewAdErrorNoAdReady = -1401, /*广告没有准备好,无法播放*/
    MobiDrawViewAdErrorInvalidPosid = -1500, /*无效的广告位id*/
    MobiDrawViewAdErrorInvalidReward = -1600, /*无效的奖励*/
    MobiDrawViewAdErrorNoRewardSelected = -1601, /*没有奖励*/
} MobiDrawViewErrorCode;

/// extern关键字用来声明一个变量,表示定义在别的地方,不在这里
extern NSString * const MobiDrawViewAdsSDKDomain;

@interface NSError (MobiDrawView)

+ (NSError *)drawViewErrorWithCode:(MobiDrawViewErrorCode)code localizedDescription:(NSString *)description;

@end
