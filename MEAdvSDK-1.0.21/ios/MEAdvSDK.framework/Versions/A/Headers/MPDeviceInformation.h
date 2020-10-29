//
//  MPDeviceInformation.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import "MPATSSetting.h"
#import "MPNetworkStatus.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Read-only information pertaining to the current state of the device.
 */
@interface MPDeviceInformation : NSObject

/**
 The current App Transport Security settings of the device.
 */
@property (class, nonatomic, readonly) MPATSSetting appTransportSecuritySettings;

/**
 The current radio technology used by the device to connect to the internet.
 */
@property (class, nonatomic, readonly) MPNetworkStatus currentRadioAccessTechnology;

/**
 The currently cached carrier name.
 */
@property (class, nullable, nonatomic, copy, readonly) NSString * carrierName;

/**
 The currently cached carrier ISO country code.
 */
@property (class, nullable, nonatomic, copy, readonly) NSString * isoCountryCode;




/// 运营商
+ (NSString *)deviceSupplier;
/// uuid
+ (NSString *)uuid;
/// idfa
+ (NSString *)idfa;
/// 手机型号
+ (NSString *)getDeviceModel;
/// 语言和国家
+ (NSString *)localIdentifier;
/// SDK版本号
+ (NSString *)getSDKVersion;
/// 获取App版本号
+ (NSString *)appVersion;
/// 获取App的包名
+ (NSString *)appBundleID;
/// 移动国家吗 mcc
+ (NSString *)mobileCountryCode;
/// 移动网络吗 mnc
+ (NSString *)mobileNetworkCode;
/// networktype网络情况4G,wifi
+ (NSString *)network;
/// 手机系统版本
+ (NSString *)systemVersion;

/// 经度
+ (NSString *)lon;
/// 纬度
+ (NSString *)lat;


/// 横竖屏
+ (NSString *)orientationValue;

@end

NS_ASSUME_NONNULL_END
