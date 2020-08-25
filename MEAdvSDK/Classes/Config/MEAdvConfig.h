//
//  MEAdvConfig.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/5/13.
//

#ifndef MEAdvConfig_h
#define MEAdvConfig_h


#endif /* MEAdvConfig_h */

@class MEAdBaseManager;

#if DEBUG
#define kBaseRequestURL @"http://dev.findwxapp.com/flow-mediation/v1/ad"
#else
#define kBaseRequestURL @"http://proto.findwxapp.com/flow-mediation/v1/ad"
#endif

#define kSDKVersion @"1.0.0"


/// 广告平台
typedef NS_ENUM(NSUInteger, MEAdAgentType) {
    MEAdAgentTypeAll,   // 所有可用的平台
    MEAdAgentTypeNone = 0,
    MEAdAgentTypeGDT,   // 广点通
    MEAdAgentTypeBUAD,  // 穿山甲
    MEAdAgentTypeAdmob,  // 谷歌
    MEAdAgentTypeFacebook,  // Facebook
    MEAdAgentTypeKS,  // 快手
    MEAdAgentTypeValpub, // Valpub,和广点通无法并存
    MEAdAgentTypeMobiSDK,   // Mobipub,自有广告SDK
    MEAdAgentTypeCount,
};

/// 广告类型
typedef NS_ENUM(NSUInteger, MEAdType) {
    MEAdType_Feed = 1,      // 普通信息流
    MEAdType_Render_Feed,   // 自渲染信息流
    MEAdType_Interstitial,  // 插屏
    MEAdType_RewardVideo,   // 激励视频
    MEAdType_Splash,        // 开屏广告
};

// block回调
typedef void(^MEBaseSplashAdLoadFinished)(void);                // 开屏广告加载成功
typedef void(^MEBaseSplashAdShowFinished)(void);                // 开屏广告展示成功
typedef void(^MEBaseSplashAdFailed)(NSError *error);            // 开屏广告展示失败
typedef void(^MEBaseSplashAdCloseClick)(void);                  // 开屏广告被关闭
typedef void(^MEBaseSplashAdClick)(void);                       // 开屏广告被点击
typedef void(^MEBaseSplashAdDismiss)(void);                     // 开屏广告被点击后,回到应用

typedef void(^MEBaseFeedAdLoadFinished)(NSArray *feedViews);    // 信息流广告加载成功)
typedef void(^MEBaseFeedAdShowFinished)(UIView *feedView);      // 信息流广告展示成功
typedef void(^MEBaseFeedAdFailed)(NSError *error);              // 信息流广告展示失败
typedef void(^MEBaseFeedAdCloseClick)(void);                    // 信息流广告被关闭
typedef void(^MEBaseFeedAdClick)(void);                         // 信息流广告被点击

typedef void(^MEBaseInterstitialLoadAdFinished)(void);          // 插屏广告加载成功
typedef void(^MEBaseInterstitialShowAdFinished)(void);          // 插屏广告展示成功
typedef void(^MEBaseInterstitialAdFailed)(NSError *error);      // 插屏广告展示失败
typedef void(^MEBaseInterstitialAdCloseClick)(void);            // 插屏广告被关闭
typedef void(^MEBaseInterstitialAdClick)(void);                 // 插屏广告被点击
typedef void(^MEBaseInterstitialAdDismiss)(void);               // 插屏广告被点击后,回到应用

typedef void(^MEBaseRewardVideoLoadFinish)(void);               // 视频广告加载成功
typedef void(^MEBaseRewardVideoDidDownload)(void);              // 视频广告缓存完成,建议在此弹出视频
typedef void(^MEBaseRewardVideoShowFinish)(void);               // 视频广告展示成功
typedef void(^MEBaseRewardVideoFailed)(NSError *error);         // 视频广告展示失败
typedef void(^MEBaseRewardVideoFinishPlay)(void);               // 视频广告播放完毕
typedef void(^MEBaseRewardVideoClick)(void);                    // 点击视频广告
typedef void(^MEBaseRewardVideoCloseClick)(void);               // 视频广告被关闭

#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#define kScreenWidth [[UIApplication sharedApplication]keyWindow].bounds.size.width
#define kScreenHeight [[UIApplication sharedApplication]keyWindow].bounds.size.height

#define kRequestConfigNotify @"kRequestConfigNotify"

#define FilePath_AllConfig  [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"MEAdvertiseAllConfig.plist"]


@protocol MESplashDelegate <NSObject>
@optional
/// 开屏广告加载成功
- (void)splashLoadSuccess:(MEAdBaseManager *)adManager;
/// 开屏广告展现成功
- (void)splashShowSuccess:(MEAdBaseManager *)adManager;
/// 开屏广告展现失败
- (void)splashShowFailure:(NSError *)error;
/// 开屏广告被关闭
- (void)splashClosed:(MEAdBaseManager *)adManager;
/// 开屏广告被点击
- (void)splashClicked:(MEAdBaseManager *)adManager;
/// 广告被点击后又取消的回调
- (void)splashDismiss:(MEAdBaseManager *)adManager;
@end

@protocol MEInterstitialDelegate <NSObject>
@optional
/// 广告加载成功
- (void)interstitialLoadSuccess:(MEAdBaseManager *)adManager;
/// 广告展现成功
- (void)interstitialShowSuccess:(MEAdBaseManager *)adManager;
/// 广告展现失败
- (void)interstitialShowFailure:(NSError *)error;
/// 广告被关闭
- (void)interstitialClosed:(MEAdBaseManager *)adManager;
/// 广告被点击
- (void)interstitialClicked:(MEAdBaseManager *)adManager;
/// 广告被点击后又取消的回调
- (void)interstitialDismiss:(MEAdBaseManager *)adManager;
@end

@protocol MEFeedViewDelegate <NSObject>
@optional
/// 信息流广告加载成功
- (void)feedViewLoadSuccess:(MEAdBaseManager *)adManager feedViews:(NSArray *)feedViews;
/// 信息流广告展现成功
- (void)feedViewShowSuccess:(MEAdBaseManager *)adManager feedView:(UIView *)feedView;
/// 信息流广告展现失败
- (void)feedViewShowFailure:(NSError *)error;

/// 信息流广告被关闭
- (void)feedViewCloseClick:(MEAdBaseManager *)adManager;

/// 信息流广告被点击
- (void)feedViewClicked:(MEAdBaseManager *)adManager;

@end

@protocol MERewardVideoDelegate <NSObject>
@optional
- (void)rewardVideoLoadSuccess:(MEAdBaseManager *)adManager;
/// 为防止播放时卡顿,在此回调后展示激励视频比较好
- (void)rewardVideoDidDownloadSuccess:(MEAdBaseManager *)adManager;
/// 展现video成功
- (void)rewardVideoShowSuccess:(MEAdBaseManager *)adManager;

/// 展现video失败
- (void)rewardVideoShowFailure:(NSError *)error;

/// 视频广告播放完毕
- (void)rewardVideoFinishPlay:(MEAdBaseManager *)adManager;

/// video被点击
- (void)rewardVideoClicked:(MEAdBaseManager *)adManager;

/// video关闭事件
- (void)rewardVideoClose:(MEAdBaseManager *)adManager;

@end

@protocol MEFullscreenVideoDelegate <NSObject>
@optional
/// 全屏视频数据加载完毕
- (void)fullscreenVideoLoadSuccess:(MEAdBaseManager *)adManager;
/// 为防止播放时卡顿,在此回调后展示全屏视频比较好
- (void)fullscreenDidDownloadSuccess:(MEAdBaseManager *)adManager;
/// 展现video成功
- (void)fullscreenShowSuccess:(MEAdBaseManager *)adManager;

/// 展现video失败
- (void)fullscreenVideoAdFailed:(NSError *)error;

/// 视频广告播放完毕
- (void)fullscreenFinishPlay:(MEAdBaseManager *)adManager;

/// video被点击
- (void)fullscreenClicked:(MEAdBaseManager *)adManager;

/// video关闭事件
- (void)fullscreenClose:(MEAdBaseManager *)adManager;
/// video 点击跳过
- (void)fullscreenClickSkip:(MEAdBaseManager *)adManager;

@end
