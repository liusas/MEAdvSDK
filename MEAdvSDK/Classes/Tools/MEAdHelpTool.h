//
//  MEAdHelpTool.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEAdHelpTool : NSObject

/// 运营商
+ (NSString *)deviceSupplier;
/// uuid
+ (NSString *)uuid;
/// idfa
+ (NSString *)idfa;
/// 手机型号
+ (NSString *)getDeviceModel;
/// 手机系统版本
+ (NSString *)systemVersion;
/// 语言和国家
+ (NSString *)localIdentifier;
/// SDK版本号
+ (NSString *)getSDKVersion;
/// networktype网络情况4G,wifi
+ (NSString *)network;

/// 经度
+ (NSString *)lon;
/// 纬度
+ (NSString *)lat;

// 获取时间戳,以天为单位
+ (NSString *)getDayStr;
// 获取时间戳,以分为单位
+ (NSString *)getTimeStr;

@end

NS_ASSUME_NONNULL_END
