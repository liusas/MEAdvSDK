//
//  MobiAdNativeBaseClass.h
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobiAdTact.h"
#import "MobiAdNativeImg.h"
#import "MobiAdNativeDlink.h"
#import "MobiAdNativeBaseClass.h"

/// 信息流广告类型
typedef NS_ENUM(NSInteger, MobiAdFeedType) {
    MobiAdFeedTypeSingleImage = 10201, // 单图
    MobiAdFeedTypeTripleImage = 10211, // 三图
};

/// 插屏广告类型,虽然现在只有一种,为防止日后扩展,所以分类
typedef NS_ENUM(NSInteger, MobiAdIntersitialType) {
    MobiAdIntersitialType1 = 10503, // 插屏
};

/// 开屏广告类型,虽然现在只有一种,为防止日后扩展,所以分类
typedef NS_ENUM(NSInteger, MobiAdSplashType) {
    MobiAdSplashType1 = 10602, // 开屏
};

@interface MobiAdNativeBaseClass : NSObject
/// 一级样式：102-native，105-插屏，106-开屏
@property (nonatomic, assign) double styleType;
/// 信息流:单图480*360,一级样式id:102,二级样式id:10201,素材描述主图：480*360、标题、描述
/// 信息流:三图480*360,一级样式id:102,二级样式id:10211,主图：480*360 X 3、标题、描述
/// 插屏:插屏640*360,一级样式id:105,二级样式id:10503,图片：640*360
/// 开屏:开屏720*1280,一级样式id:106,二级样式id:10602,图片：720*1280
/// 全屏视频:全屏视频720*1280,一级样式id:104,二级样式id:10401,视频：720*1280，mp4
/// 全屏视频:全屏视频1280*720,一级样式id:104,二级样式id:10402,视频：1280*720，mp4
/// 激励视频:激励视频720*1280,一级样式id:106,二级样式id:10602视频：720*1280，mp4
@property (nonatomic, assign) double style;
/// 广告点击跳转行为：
/// 1 - Goole Play / App Store
/// 2 - Browser
/// 3 - webview
/// 4 - Deeplink
@property (nonatomic, assign) double ctype;
/// 广告id
@property (nonatomic, strong) NSString *adid;
/// 广告包名
@property (nonatomic, strong) NSString *pkg;
/// 图标地址
@property (nonatomic, strong) NSString *logo;
/// 广告描述
@property (nonatomic, strong) NSString *desc;
/// 广告标题
@property (nonatomic, strong) NSString *title;
/// 图片数组
@property (nonatomic, strong) NSArray *img;
/// 落地页跳转地址 或者 下载地址
@property (nonatomic, strong) NSString *curl;

/// 展现上报url数组
@property (nonatomic, strong) NSArray *impTrack;
/// 点击上报url数组
@property (nonatomic, strong) NSArray *clkTrack;
/// 开始下载上报数组
@property (nonatomic, strong) NSArray *startDownload;
/// 下载结束上报数组
@property (nonatomic, strong) NSArray *finishDownload;
/// 开始安装上报数组
@property (nonatomic, strong) NSArray *startInstall;
/// 安装结束上报数组
@property (nonatomic, strong) NSArray *finishInstall;
/// app激活上报数组
@property (nonatomic, strong) NSArray *activeApp;

/// deeplink调起成功上报数组
@property (nonatomic, strong) NSArray *dlinkTrack;
/// deeplink地址
@property (nonatomic, strong) NSString *dlinkDurl;
/// deeplink下载地址
@property (nonatomic, strong) NSString *dlinkWurl;

/// 策略相关信息
@property (nonatomic, strong) MobiAdTact *tact;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
