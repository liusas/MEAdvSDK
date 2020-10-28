//
//  AppConfig.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/30.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <Foundation/Foundation.h>

// App Name
#define kAppName kAppInfoDictionary[@"CFBundleDisplayName"] ?: kAppInfoDictionary[@"CFBundleName"]
// App 版本号
#define kAppVersion [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

//iPhone5大小
#define iPhone5Below ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? 640.f ==  [[UIScreen mainScreen] currentMode].size.width : NO)
#define IsiPhone11 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) : NO)
#define IsiPhone11Pro ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define IsiPhone11ProMax ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)



// iPhone X, iPhone Xs, iPhone Xs Max, iPhone XR
#define iPhoneXSeries \
({\
    BOOL isPhoneX = NO;\
    if (@available(iOS 11.0, *)) {\
        isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
    }\
    (isPhoneX);})

#define iPhoneXBotommMargin 34.f
#define iPhoneXTopMargin 44.f
#define iPhoneXSafeHeight (SCREEN_HEIGHT - iPhoneXTopMargin - iPhoneXBotommMargin)

// 获取相对于 4.7寸屏幕的宽或高
#define kCurrentWidth(width) (width / 375.f * SCREEN_WIDTH)
#define kCurrentHeight(height) (height / 667.f * SCREEN_HEIGHT)

#define SCALETO2X SCREEN_WIDTH/375.f

#define kScreenWidth [[UIApplication sharedApplication]keyWindow].bounds.size.width
#define kScreenHeight [[UIApplication sharedApplication]keyWindow].bounds.size.height

#define IPHONEX_TABBAR_FIX_HEIGHT 34
#define IPHONEX_TOPBAR_FIX_HEIGHT 44
#define ISIPHONEX ([[UIApplication sharedApplication] statusBarFrame].size.height == 44) || ([UIScreen mainScreen].bounds.size.height == 812 || [UIScreen mainScreen].bounds.size.height == 896) || ([UIScreen mainScreen].bounds.size.width == 812 || [UIScreen mainScreen].bounds.size.width == 896)

//屏幕尺寸
//#define kAutoSizeScaleX ([[MEAppUtil shareInstance] autoSizeScaleX])
//#define kAutoSizeScaleY ([[MEAppUtil shareInstance] autoSizeScaleY])
//#define kScreen_width   ([UIScreen mainScreen].bounds.size.width)
//#define kScreen_height  ([UIScreen mainScreen].bounds.size.height)

#define kHeight(var) ((var) * kAutoSizeScaleY)
#define kWidth(var) ((var) * kAutoSizeScaleX)
#define kRight(var) ((var) * kAutoSizeScaleX)
#define kLeft(var) ((var) * kAutoSizeScaleX)
#define kBottom(var) ((var) * kAutoSizeScaleX)
#define kTop(var) ((var) * kAutoSizeScaleX)
#define kScaleValue(x) kWidth(x)

//字重
#define RegularFontName         [NSString stringWithFormat:@"PingFangSC-Regular"]
#define MediumFontName         [NSString stringWithFormat:@"PingFangSC-Medium"]
#define LightFontName         [NSString stringWithFormat:@"PingFangSC-Light"]
#define BoldFontName         [NSString stringWithFormat:@"DIN Alternate Bold"]
#define SemiboldFontName         [NSString stringWithFormat:@"PingFangSC-Semibold"]
#define DinboldFontName         [NSString stringWithFormat:@"DIN-Bold"]


#define iPhoneNavigationBarHeight 44
// Status bar height.
#define iPhoneStatusBarHeight (iPhoneXSeries ? iPhoneXTopMargin : 20.f)
// Tabbar height.
#define iPhoneTabbarHeight (49.f + (iPhoneXSeries ? iPhoneXBotommMargin : 0.f))
// safe bottom margin.
#define  iPhoneSafeBottomMargin (iPhoneXSeries ? iPhoneXBotommMargin : 0.f)
// Status bar & navigation bar height.
#define iPhoneStatusBarAndNavigationBarHeight (iPhoneStatusBarHeight + iPhoneNavigationBarHeight)

#define  ISFirstLanuch @"iSFirstLanuch"
// 退入后台多久后打开要展示开屏广告,目前是5秒
#define kSplashTimeLimit 5
// 轮播图单张持续时间
#define kCycleVCTime 4
// 轮播图限制个数
#define kCycleNumLimit 3
// 悬浮金币限制个数
#define kSuspendGoldenLimitCount 20
// 悬浮金币浮现间隔, 10s
#define kSuspendGoldenShowInterval 10

// 步数与公里数换算
#define kStepToDistance(COUNT) COUNT / 1300
// 步数换算成秒 100步=1分钟
#define kStepToTime(COUNT) COUNT / (10 / 6)
// 步数与卡路里换算
#define kStepToCalorie(COUNT) COUNT / 18.6


//// 悬浮金币位置
//typedef NS_ENUM(NSInteger, GoldenLocation) {
//    GoldenLocationTopLeft = 1, // 左上
//    GoldenLocationTopRight, //右上
//    GoldenLocationBottomLeft, // 左下
//    GoldenLocationBottomRight, // 右下
//};
//
///// 红包类型
//typedef NS_ENUM(NSInteger, RedEvelopesType) {
//    RedEvelopesNewUser = 1, // 新人红包
//    RedEvelopesTypeSurprise, // 惊喜红包
//};

////广告位置
//typedef NS_ENUM(NSInteger,CYAdPositionType) {
//    CYAdPositionTypeOpenApp = 1, //开屏
//    CYAdPositionTypeHomeTop = 2,//首页轮播
//    CYAdPositionTypeWelfare = 3,//福利社
//    CYAdPositionTypeCommunity = 4,//社区
//    CYAdPositionTypeNewCommunity = 5,//社区新的
//    CYAdPositionTypeHomeMiddle = 6,//潜客首页中部
//    CYAdPositionTypeShopTop = 7,//商城顶部
//    CYAdPositionTypeShopMiddle = 10,//商城中部
//    CYAdPositionTypeWelfareTop = 11,//福利社顶部
//    CYAddPositionTypeWelfareMiddle = 12,//福利社banner中部
//    CYAddPositionTypeShopCarMiddle = 26,//商城首页下方广告位-整车
//    CYAddPositionTypeShopProductMiddle = 27,//商城首页下方广告位-优品
//    CYAddPositionTypeSquare = 16,//社区广场Banner
//    CYAddPositionTypeADIng = 17,//首页正在进行
//    CYAddPositionTypeADNewshopTopRecommend = 28,//新商城推荐顶部广告位
//    CYAddPositionTypeADNewshopTopProduct = 29,// 新商城菱菱优品顶部广告位
//    CYAddPositionTypeADNewshopTopCar = 30,// 新商城整车顶部广告位
//    CYAddPositionTypeADServiceMiddleOrderServe = 32,// 服务中部预约服务的广告位
//};

///**
// 刷新方向
// */
//typedef NS_ENUM(NSInteger, CYRefreshType) {
//   CYRefreshTypeMore = 0, // 更多
//   CYRefreshTypeNew  = 1, // 最新（这版1不启用）
//};
//
///// 分享平台
//typedef NS_ENUM(NSInteger,CYSharePlatformType){
//    CYSharePlatformType_Other = 0, //其他
//    CYSharePlatformType_Wechat = 1, //微信
//    CYSharePlatformType_QQ = 2,//QQ
//    CYSharePlatformType_QQQzone = 3,//QQ空间
//    CYSharePlatformType_WechatTimeLine = 4,//微信朋友圈
//    CYSharePlatformType_Sina = 5,//新浪微博
//};
//
///// 底部是否展示工具栏
//typedef NS_ENUM(NSInteger, ShowTabbarOrNot) {
//    canShowTabbar = 1,  /**< 展示底部工具栏*/
//    canNotShowTabbar = 2,   /**< 不展示底部工具栏*/
//};
