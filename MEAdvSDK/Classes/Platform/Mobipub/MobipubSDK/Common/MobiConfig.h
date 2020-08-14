//
//  MobiConfig.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/6.
//  请求下来的广告配置由MobiConfig类统一管理

#import <Foundation/Foundation.h>
#import "MobiAdNativeBaseClass.h"
#import "MobiAdVideoBaseClass.h"
#import "MobiAdBannerBaseClass.h"
#import "MobiGlobal.h"

NS_ASSUME_NONNULL_BEGIN

/// 广告位类型
typedef NS_ENUM(NSInteger, MobiAdType) {
    MobiAdTypeBanner = 101, // 横幅广告
    MobiAdTypeFeed = 102, // 信息流
    MobiAdTypeRewardedVideo = 103, // 激励视频
    MobiAdTypeFullScreenVideo = 104, // 全屏视频
    MobiAdTypeInterstitial = 105, // 插屏
    MobiAdTypeSplash = 106, // 开屏
    MobiAdTypeUnknown, // 未知
};

@interface MobiConfig : NSObject

@property (nonatomic, assign) BOOL isFullscreenAd;

/// 该配置下的广告类型
@property (nonatomic, assign) MobiAdType adType;
/// 信息流,插屏,开屏的配置数据
@property (nonatomic, strong) MobiAdNativeBaseClass *nativeConfigData;
/// 激励视频,全屏视频的配置数据
@property (nonatomic, strong) MobiAdVideoBaseClass *videoConfigData;
/// banner 配置数据
@property (nonatomic, strong) MobiAdBannerBaseClass *bannerConfigData;

/// 用于执行具体广告的customEvent类
@property (nonatomic, assign) Class customEventClass;
/// 广告请求时长限制
@property (nonatomic, assign) NSTimeInterval adTimeoutInterval;
/// 当前广告是否有效
@property (nonatomic, assign) BOOL adUnitWarmingUp;

/// 开屏是否支持预加载
@property (nonatomic, assign) BOOL precacheRequired;
/// 是否是支持 vast 协议的激励视频
@property (nonatomic, assign) BOOL isVastVideoPlayer;
/// 服务端返回的理想 size
@property (nonatomic, assign) CGSize preferredSize;
/// 插屏支持的方向
@property (nonatomic, assign) MobiInterstitialOrientationType orientationType;
/// 至少展示多少时长才能记为展现
@property (nonatomic) NSTimeInterval impressionMinVisibleTimeInSec;
/// 至少展示多少像素才能记为展现
@property (nonatomic) CGFloat impressionMinVisiblePixels;
/// 刷新时间, 默认 300s
@property (nonatomic, assign) NSTimeInterval refreshInterval;

/// 展现上报url数组
@property (nonatomic, strong) NSArray<NSURL *> * impressionTrackingURLs;
/// 点击上报url数组
@property (nonatomic, strong) NSArray<NSURL *> * clickTrackingURLs;
/// 开始下载上报的url数组
@property (nonatomic, strong) NSArray<NSURL *> * startDownloadTrackingURLs;
/// 结束下载上报的url数组
@property (nonatomic, strong) NSArray<NSURL *> * finishDownloadTrackingURLs;
/// 安卓需要,iOS不需要,开始安装
@property (nonatomic, strong) NSArray<NSURL *> * startInstallTrackingURLs;
/// 安卓需要,iOS不需要,安装完成
@property (nonatomic, strong) NSArray<NSURL *> * finishInstallTrackingURLs;
///信息流广告尺寸，必须传入宽度，高度自适应，否则无法展示信息流
@property (nonatomic, assign) CGSize feedSize;

/*******************点击上报**********************/
// 手指按下的 x,y
@property(nonatomic,assign) CGPoint clickDownPoint;
// 手指抬起的 x,y
@property(nonatomic,assign) CGPoint clickUpPoint;

/// 请求下来的广告配置字典,转化成数据模型
- (instancetype)initWithAdConfigResponse:(NSDictionary *)json;

// Default init is unavailable
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)hasPreferredSize;
- (NSString *)adResponseHTMLString;

@end

NS_ASSUME_NONNULL_END
