//
//  MobiBannerError.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import <Foundation/Foundation.h>

typedef enum {
    MobiBannerAdErrorUnknown = -1, /*未知错误*/

    MobiBannerAdErrorTimeout = -1000, /*超时错误*/
    MobiBannerAdErrorAdUnitWarmingUp = -1001, /*广告单元正在预热,请稍后重试*/
    MobiBannerAdErrorNoAdsAvailable = -1100, /*没有有效广告*/
    MobiBannerAdErrorInvalidCustomEvent = -1200, /*无效的信息流执行工具*/
    MobiBannerAdErrorMismatchingAdTypes = -1300, /*广告类型不匹配*/
    MobiBannerAdErrorNoAdReady = -1401, /*广告没有准备好,无法展示*/
    MobiBannerAdErrorInvalidPosid = -1500, /*无效的广告位id*/
} MobiBannerErrorCode;

/// extern关键字用来声明一个变量,表示定义在别的地方,不在这里
extern NSString * const MobiBannerAdsSDKDomain;

@interface NSError (MobiBanner)

+ (NSError *)feedErrorWithCode:(MobiBannerErrorCode)code localizedDescription:(NSString *)description;

@end
