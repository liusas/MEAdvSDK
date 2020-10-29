//
//  MobiAdVideoBaseClass.h
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobiAdVideoVideoAdm.h"
#import "MobiAdVideoBaseClass.h"
#import "MobiAdTact.h"

/// 全屏视频广告类型
typedef NS_ENUM(NSInteger, MobiAdFullScreenVideoType) {
    MobiAdFullScreenVideoTypeLandscape = 10401, // 全屏竖屏
    MobiAdFullScreenVideoTypePortrait = 10402, // 全屏横屏
};

/// 激励视频广告类型,虽然现在只有一种,为防止日后扩展,所以分类
typedef NS_ENUM(NSInteger, MobiAdRewardedVideoType) {
    MobiAdRewardedVideoTypeLandscape = 10602, // 激励视频竖屏
};


@interface MobiAdVideoBaseClass : NSObject
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
/// 视频素材及上报内容
@property (nonatomic, strong) MobiAdVideoVideoAdm *videoAdm;
/// app激活上报数组
@property (nonatomic, strong) NSArray *activeApp;
/// 开始下载上报数组
@property (nonatomic, strong) NSArray *startDownload;
/// 下载结束上报数组
@property (nonatomic, strong) NSArray *finishDownload;
/// 开始安装上报数组
@property (nonatomic, strong) NSArray *startInstall;
/// 安装结束上报数组
@property (nonatomic, strong) NSArray *finishInstall;
/// 广告id
@property (nonatomic, strong) NSString *adid;
/// 广告点击跳转行为：
/// 1 - Goole Play / App Store
/// 2 - Browser
/// 3 - webview
/// 4 - Deeplink
@property (nonatomic, assign) double ctype;
/// 策略相关信息
@property (nonatomic, strong) MobiAdTact *tact;

@property (nonatomic, copy) NSString *dlink_durl;
@property (nonatomic, copy) NSString *dlink_wurl;
@property (nonatomic, copy) NSString *curl;
///deeplink吊起成功上报数组
@property (nonatomic, copy) NSArray *dlink_track;
///点击上报数组
@property (nonatomic, copy) NSArray *clk_track;
///展现上报URL数组
@property (nonatomic, copy) NSArray *img_track;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
