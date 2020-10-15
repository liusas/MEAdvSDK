//
//  MPDeviceInformation.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "MPDeviceInformation.h"
#import "NSDictionary+MPAdditions.h"
#import <CoreTelephony/CTCarrier.h>
#import <AdSupport/AdSupport.h>
#import <sys/utsname.h>
#import "MPConstants.h"
#import "MPReachabilityManager.h"
#import <UIKit/UIKit.h>

// ATS Constants
static NSString *const kMoPubAppTransportSecurityDictionaryKey                       = @"NSAppTransportSecurity";
static NSString *const kMoPubAppTransportSecurityAllowsArbitraryLoadsKey             = @"NSAllowsArbitraryLoads";
static NSString *const kMoPubAppTransportSecurityAllowsArbitraryLoadsForMediaKey     = @"NSAllowsArbitraryLoadsForMedia";
static NSString *const kMoPubAppTransportSecurityAllowsArbitraryLoadsInWebContentKey = @"NSAllowsArbitraryLoadsInWebContent";
static NSString *const kMoPubAppTransportSecurityAllowsLocalNetworkingKey            = @"NSAllowsLocalNetworking";
static NSString *const kMoPubAppTransportSecurityRequiresCertificateTransparencyKey  = @"NSRequiresCertificateTransparency";
/// 竖屏
static NSString * const kMoPubInterfaceOrientationPortrait = @"p";
/// 横屏
static NSString * const kMoPubInterfaceOrientationLandscape = @"l";

// Carrier Constants
static NSString *const kMoPubCarrierInfoDictionaryKey    = @"com.mopub.carrierinfo";
static NSString *const kMoPubCarrierNameKey              = @"carrierName";
static NSString *const kMoPubCarrierISOCountryCodeKey    = @"isoCountryCode";
static NSString *const kMoPubCarrierMobileCountryCodeKey = @"mobileCountryCode";
static NSString *const kMoPubCarrierMobileNetworkCodeKey = @"mobileNetworkCode";

@implementation MPDeviceInformation

#pragma mark - Initialization

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Asynchronously fetch an updated copy of the device's carrier settings
        // and cache it. This must be performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            CTTelephonyNetworkInfo *networkInfo = CTTelephonyNetworkInfo.new;
            [MPDeviceInformation updateCarrierInfoCache:networkInfo.subscriberCellularProvider];
        });
    });
}

#pragma mark - ATS

+ (MPATSSetting)appTransportSecuritySettings {
    // Keep track of ATS settings statically, as they'll never change in the lifecycle of the application.
    // This way, the setting value only gets assembled once.
    static BOOL gCheckedAppTransportSettings = NO;
    static MPATSSetting gSetting = MPATSSettingEnabled;

    // If we've already checked ATS settings, just use what we have
    if (gCheckedAppTransportSettings) {
        return gSetting;
    }

    // Otherwise, figure out ATS settings
    // Start with the assumption that ATS is enabled
    gSetting = MPATSSettingEnabled;

    // Grab the ATS dictionary from the Info.plist
    NSDictionary *atsSettingsDictionary = [NSBundle mainBundle].infoDictionary[kMoPubAppTransportSecurityDictionaryKey];

    // Check if ATS is entirely disabled, and if so, add that to the setting value
    if ([atsSettingsDictionary[kMoPubAppTransportSecurityAllowsArbitraryLoadsKey] boolValue]) {
        gSetting |= MPATSSettingAllowsArbitraryLoads;
    }

    // New App Transport Security keys were introduced in iOS 10. Only send settings for these keys if we're running iOS 10 or greater.
    // They may exist in the dictionary if we're running iOS 9, but they won't do anything, so the server shouldn't know about them.
    if (@available(iOS 10, *)) {
        // In iOS 10, NSAllowsArbitraryLoads gets ignored if ANY keys of NSAllowsArbitraryLoadsForMedia,
        // NSAllowsArbitraryLoadsInWebContent, or NSAllowsLocalNetworking are PRESENT (i.e., they can be set to `false`)
        // See: https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW34
        // If needed, flip NSAllowsArbitraryLoads back to 0 if any of these keys are present.
        if (atsSettingsDictionary[kMoPubAppTransportSecurityAllowsArbitraryLoadsForMediaKey] != nil
            || atsSettingsDictionary[kMoPubAppTransportSecurityAllowsArbitraryLoadsInWebContentKey] != nil
            || atsSettingsDictionary[kMoPubAppTransportSecurityAllowsLocalNetworkingKey] != nil) {
            gSetting &= (~MPATSSettingAllowsArbitraryLoads);
        }

        if ([atsSettingsDictionary[kMoPubAppTransportSecurityAllowsArbitraryLoadsForMediaKey] boolValue]) {
            gSetting |= MPATSSettingAllowsArbitraryLoadsForMedia;
        }
        if ([atsSettingsDictionary[kMoPubAppTransportSecurityAllowsArbitraryLoadsInWebContentKey] boolValue]) {
            gSetting |= MPATSSettingAllowsArbitraryLoadsInWebContent;
        }
        if ([atsSettingsDictionary[kMoPubAppTransportSecurityRequiresCertificateTransparencyKey] boolValue]) {
            gSetting |= MPATSSettingRequiresCertificateTransparency;
        }
        if ([atsSettingsDictionary[kMoPubAppTransportSecurityAllowsLocalNetworkingKey] boolValue]) {
            gSetting |= MPATSSettingAllowsLocalNetworking;
        }
    }

    gCheckedAppTransportSettings = YES;
    return gSetting;
}

#pragma mark - Connectivity

+ (MPNetworkStatus)currentRadioAccessTechnology {
    static CTTelephonyNetworkInfo *gTelephonyNetworkInfo = nil;

    if (gTelephonyNetworkInfo == nil) {
        gTelephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    }
    NSString *accessTechnology = gTelephonyNetworkInfo.currentRadioAccessTechnology;

    // The determination of 2G/3G/4G technology is a best-effort.
    if ([accessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) { // Source: https://en.wikipedia.org/wiki/LTE_(telecommunication)
        return MPReachableViaCellularNetwork4G;
    }
    else if ([accessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] || // Source: https://www.phonescoop.com/glossary/term.php?gid=151
             [accessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] || // Source: https://www.phonescoop.com/glossary/term.php?gid=151
             [accessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] || // Source: https://www.phonescoop.com/glossary/term.php?gid=151
             [accessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA] || // Source: https://www.techopedia.com/definition/24282/wideband-code-division-multiple-access-wcdma
             [accessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA] || // Source: https://en.wikipedia.org/wiki/High_Speed_Packet_Access#High_Speed_Downlink_Packet_Access_(HSDPA)
             [accessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) { // Source: https://en.wikipedia.org/wiki/High_Speed_Packet_Access#High_Speed_Uplink_Packet_Access_(HSUPA)
        return MPReachableViaCellularNetwork3G;
    }
    else if ([accessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x] || // Source: In testing, this mode showed up when the phone was in Verizon 1x mode
             [accessTechnology isEqualToString:CTRadioAccessTechnologyGPRS] || // Source: https://en.wikipedia.org/wiki/General_Packet_Radio_Service
             [accessTechnology isEqualToString:CTRadioAccessTechnologyEdge] || // Source: https://en.wikipedia.org/wiki/2G#2.75G_(EDGE)
             [accessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) { // Source: https://www.phonescoop.com/glossary/term.php?gid=155
        return MPReachableViaCellularNetwork2G;
    }

    return MPReachableViaCellularNetworkUnknownGeneration;
}

+ (void)updateCarrierInfoCache:(CTCarrier *)carrierInfo {
    // Using `setValue` instead of `setObject` here because `carrierInfo` could be `nil`,
    // and any of its properties could be `nil`.
    NSMutableDictionary *updatedCarrierInfo = [NSMutableDictionary dictionaryWithCapacity:4];
    [updatedCarrierInfo setValue:carrierInfo.carrierName forKey:kMoPubCarrierNameKey];
    [updatedCarrierInfo setValue:carrierInfo.isoCountryCode forKey:kMoPubCarrierISOCountryCodeKey];
    [updatedCarrierInfo setValue:carrierInfo.mobileCountryCode forKey:kMoPubCarrierMobileCountryCodeKey];
    [updatedCarrierInfo setValue:carrierInfo.mobileNetworkCode forKey:kMoPubCarrierMobileNetworkCodeKey];

    [NSUserDefaults.standardUserDefaults setObject:updatedCarrierInfo forKey:kMoPubCarrierInfoDictionaryKey];
}

+ (NSString *)carrierName {
    NSDictionary *carrierInfo = [NSUserDefaults.standardUserDefaults objectForKey:kMoPubCarrierInfoDictionaryKey];
    return [carrierInfo mp_stringForKey:kMoPubCarrierNameKey];
}

+ (NSString *)isoCountryCode {
    NSDictionary *carrierInfo = [NSUserDefaults.standardUserDefaults objectForKey:kMoPubCarrierInfoDictionaryKey];
    return [carrierInfo mp_stringForKey:kMoPubCarrierISOCountryCodeKey];
}

/// 运营商
+ (NSString *)deviceSupplier {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = networkInfo.subscriberCellularProvider;
    NSString *carrier_country_code = carrier.isoCountryCode;
    
    if (carrier_country_code == nil) {
        carrier_country_code = @"";
    }
    //国家编号
    NSString *CountryCode = carrier.mobileCountryCode;
    
    if (CountryCode == nil) {
        CountryCode = @"";
    }
    //网络供应商编码
    NSString *NetworkCode = carrier.mobileNetworkCode;
    
    if (NetworkCode == nil) {
        NetworkCode = @"";
    }
    
    NSString *mobile_country_code = [NSString stringWithFormat:@"%@%@",CountryCode,NetworkCode];
    
    if (mobile_country_code == nil) {
        mobile_country_code = @"";
    }
    
    NSString *carrier_name = nil;    //网络运营商的名字
    NSString *code = [carrier mobileNetworkCode];
    
    if ([code isEqualToString:@"00"] || [code isEqualToString:@"02"] || [code isEqualToString:@"07"]) {
        // ret = @"移动"
        carrier_name = @"CMCC";
    }
    
    if ([code isEqualToString:@"03"] || [code isEqualToString:@"05"]) {
        // ret = @"电信";
        carrier_name =  @"CTCC";
    }
    
    if ([code isEqualToString:@"01"] || [code isEqualToString:@"06"]) {
        // ret = @"联通";
        carrier_name =  @"CUCC";
    }
    
    if (code == nil) {
        carrier_name = @"";
    }
    
    carrier_name = [NSString stringWithFormat:@"%@-%@",carrier_name,[carrier.carrierName stringByRemovingPercentEncoding]];
    return carrier_name;
}

/// uuid
+ (NSString *)uuid {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

/// idfa
+ (NSString *)idfa {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([deviceModel isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([deviceModel isEqualToString:@"iPhone3,2"])    return @"iPhone 4";
    if ([deviceModel isEqualToString:@"iPhone3,3"])    return @"iPhone 4";
    if ([deviceModel isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceModel isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([deviceModel isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([deviceModel isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([deviceModel isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceModel isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([deviceModel isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    if ([deviceModel isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    if ([deviceModel isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    // 日行两款手机型号均为日本独占，可能使用索尼FeliCa支付方案而不是苹果支付
    if ([deviceModel isEqualToString:@"iPhone9,1"])    return @"iPhone 7";
    if ([deviceModel isEqualToString:@"iPhone9,2"])    return @"iPhone 7 Plus";
    if ([deviceModel isEqualToString:@"iPhone9,3"])    return @"iPhone 7";
    if ([deviceModel isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus";
    if ([deviceModel isEqualToString:@"iPhone10,1"])   return @"iPhone_8";
    if ([deviceModel isEqualToString:@"iPhone10,4"])   return @"iPhone_8";
    if ([deviceModel isEqualToString:@"iPhone10,2"])   return @"iPhone_8_Plus";
    if ([deviceModel isEqualToString:@"iPhone10,5"])   return @"iPhone_8_Plus";
    if ([deviceModel isEqualToString:@"iPhone10,3"])   return @"iPhone X";
    if ([deviceModel isEqualToString:@"iPhone10,6"])   return @"iPhone X";
    if ([deviceModel isEqualToString:@"iPhone11,8"])   return @"iPhone XR";
    if ([deviceModel isEqualToString:@"iPhone11,2"])   return @"iPhone XS";
    if ([deviceModel isEqualToString:@"iPhone11,6"])   return @"iPhone XS Max";
    if ([deviceModel isEqualToString:@"iPhone11,4"])   return @"iPhone XS Max";
    if ([deviceModel isEqualToString:@"iPhone12,1"])   return @"iPhone 11";
    if ([deviceModel isEqualToString:@"iPhone12,3"])   return @"iPhone 11 Pro";
    if ([deviceModel isEqualToString:@"iPhone12,5"])   return @"iPhone 11 Pro Max";
    if ([deviceModel isEqualToString:@"iPhone12,8"])   return @"iPhone SE2";
    if ([deviceModel isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([deviceModel isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([deviceModel isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([deviceModel isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([deviceModel isEqualToString:@"iPod5,1"])      return @"iPod Touch (5 Gen)";
    if ([deviceModel isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceModel isEqualToString:@"iPad1,2"])      return @"iPad 3G";
    if ([deviceModel isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([deviceModel isEqualToString:@"iPad2,2"])      return @"iPad 2";
    if ([deviceModel isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([deviceModel isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([deviceModel isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([deviceModel isEqualToString:@"iPad2,6"])      return @"iPad Mini";
    if ([deviceModel isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([deviceModel isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPad3,3"])      return @"iPad 3";
    if ([deviceModel isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([deviceModel isEqualToString:@"iPad3,5"])      return @"iPad 4";
    if ([deviceModel isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([deviceModel isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([deviceModel isEqualToString:@"iPad4,4"])      return @"iPad Mini 2 (WiFi)";
    if ([deviceModel isEqualToString:@"iPad4,5"])      return @"iPad Mini 2 (Cellular)";
    if ([deviceModel isEqualToString:@"iPad4,6"])      return @"iPad Mini 2";
    if ([deviceModel isEqualToString:@"iPad4,7"])      return @"iPad Mini 3";
    if ([deviceModel isEqualToString:@"iPad4,8"])      return @"iPad Mini 3";
    if ([deviceModel isEqualToString:@"iPad4,9"])      return @"iPad Mini 3";
    if ([deviceModel isEqualToString:@"iPad5,1"])      return @"iPad Mini 4 (WiFi)";
    if ([deviceModel isEqualToString:@"iPad5,2"])      return @"iPad Mini 4 (LTE)";
    if ([deviceModel isEqualToString:@"iPad5,3"])      return @"iPad Air 2";
    if ([deviceModel isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    if ([deviceModel isEqualToString:@"iPad6,3"])      return @"iPad Pro 9.7";
    if ([deviceModel isEqualToString:@"iPad6,4"])      return @"iPad Pro 9.7";
    if ([deviceModel isEqualToString:@"iPad6,7"])      return @"iPad Pro 12.9";
    if ([deviceModel isEqualToString:@"iPad6,8"])      return @"iPad Pro 12.9";
    
    if ([deviceModel isEqualToString:@"AppleTV2,1"])      return @"Apple TV 2";
    if ([deviceModel isEqualToString:@"AppleTV3,1"])      return @"Apple TV 3";
    if ([deviceModel isEqualToString:@"AppleTV3,2"])      return @"Apple TV 3";
    if ([deviceModel isEqualToString:@"AppleTV5,3"])      return @"Apple TV 4";
    
    if ([deviceModel isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceModel isEqualToString:@"x86_64"])       return @"Simulator";
    return deviceModel;
}

/// 语言和国家
+ (NSString *)localIdentifier {
    // iOS 获取设备当前地区的代码
    NSString *localeIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
    return localeIdentifier;
}

/// SDK版本号
+ (NSString *)getSDKVersion {
    return MP_SDK_VERSION;
}

/// 获取App版本号
+ (NSString *)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

/// 获取App的包名
+ (NSString *)appBundleID {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

+ (NSString *)mobileCountryCode {
    NSDictionary *carrierInfo = [NSUserDefaults.standardUserDefaults objectForKey:kMoPubCarrierInfoDictionaryKey];
    return [carrierInfo mp_stringForKey:kMoPubCarrierMobileCountryCodeKey];
}

+ (NSString *)mobileNetworkCode {
    NSDictionary *carrierInfo = [NSUserDefaults.standardUserDefaults objectForKey:kMoPubCarrierInfoDictionaryKey];
    return [carrierInfo mp_stringForKey:kMoPubCarrierMobileNetworkCodeKey];
}

/// 网络情况
+ (NSString *)network {
//    设备网络类型，参考ortb标准定义：
//    0 - unknown
//    1 - ethernet
//    2 - WIFI
//    3 - unknown generation
//    4 - 2G
//    5 - 3G
//    6 - 4G
    return [NSString stringWithFormat:@"%ld", (long)MPReachabilityManager.sharedManager.currentStatus];
}

+ (NSString*)systemVersion {
    return [NSString stringWithFormat:@"%.2f", [[[UIDevice currentDevice] systemVersion] floatValue]];
}


/// 经度
+ (NSString *)lon {
    return @"";
}

/// 纬度
+ (NSString *)lat {
    return @"";
}



/// 获取App名称
+ (NSString *)getAppName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

/// 横竖屏
+ (NSString *)orientationValue {
    // Starting with iOS8, the orientation of the device is taken into account when
    // requesting the key window's bounds.
    CGRect appBounds = [UIApplication sharedApplication].keyWindow.bounds;
    return appBounds.size.width > appBounds.size.height ? kMoPubInterfaceOrientationLandscape : kMoPubInterfaceOrientationPortrait;
}

/// 屏幕的缩放因子
+ (NSString *)scaleFactorValue {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        [[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        return [NSString stringWithFormat:@"%.1f", [[UIScreen mainScreen] scale]];
    } else {
        return @"1.0";
    }
}

@end
