//
//  MEBaseAdapter.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"
#import "MEFunnyButton.h"
#import "MEAdLogModel.h"

@class MEBaseAdapter;
@class GDTUnifiedNativeAdView;

#define iPhoneXSeries \
({\
    BOOL isPhoneX = NO;\
    if (@available(iOS 11.0, *)) {\
        isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
    }\
    (isPhoneX);})

/// 信息流代理回调
@protocol MEBaseAdapterFeedProtocol <NSObject>
@optional
/// 缓存的信息流广告拉取成功
- (void)adapterFeedCacheGetSuccess:(MEBaseAdapter *)adapter feedViews:(NSArray <UIView *>*)feedViews;
/// 信息流缓存广告拉取失败的回调
- (void)adapterFeedCacheGetFailed:(NSError *)error;
@required
/// 广告加载成功
- (void)adapterFeedLoadSuccess:(MEBaseAdapter *)adapter feedView:(UIView *)feedView;
/// 展现FeedView成功
- (void)adapterFeedShowSuccess:(MEBaseAdapter *)adapter feedView:(UIView *)feedView;
/// 展示自渲染FeedView成功,需要手动设置其各控件的布局
- (void)adapterFeedRenderShowSuccess:(MEBaseAdapter *)adapter feedView:(GDTUnifiedNativeAdView *)feedView;
/// 展现FeedView失败
- (void)adapter:(MEBaseAdapter *)adapter bannerShowFailure:(NSError *)error;
/// FeedView被点击
- (void)adapterFeedClicked:(MEBaseAdapter *)adapter;
/// 广告关闭事件
- (void)adapterFeedClose:(MEBaseAdapter *)adapter;
@end

/// 激励视频回调
@protocol MEBaseAdapterVideoProtocol <NSObject>

/// 广告加载成功
- (void)adapterVideoLoadSuccess:(MEBaseAdapter *)adapter;

/// 展现video成功
- (void)adapterVideoShowSuccess:(MEBaseAdapter *)adapter;

/// 展现video失败
- (void)adapter:(MEBaseAdapter *)adapter videoShowFailure:(NSError *)error;

/// 视频播放完毕回调
- (void)adapterVideoFinishPlay:(MEBaseAdapter *)adapter;

/// video被点击
- (void)adapterVideoClicked:(MEBaseAdapter *)adapter;

/// video关闭事件
- (void)adapterVideoClose:(MEBaseAdapter *)adapter;

@end

/// 开屏广告代理回调
@protocol MEBaseAdapterSplashProtocol <NSObject>
/// 广告加载成功
- (void)adapterSplashLoadSuccess:(MEBaseAdapter *)adapter;
/// 开屏展示成功
- (void)adapterSplashShowSuccess:(MEBaseAdapter *)adapter;
/// 开屏展现失败
- (void)adapter:(MEBaseAdapter *)adapter splashShowFailure:(NSError *)error;
/// 开屏被点击
- (void)adapterSplashClicked:(MEBaseAdapter *)adapter;
/// 开屏关闭事件
- (void)adapterSplashClose:(MEBaseAdapter *)adapter;
/// 开屏广告点击后,回到应用事件
- (void)adapterSplashDismiss:(MEBaseAdapter *)adapter;

@end

/// 插屏代理回调
@protocol MEBaseAdapterInterstitialProtocol <NSObject>

// 插屏广告加载成功
- (void)adapterInterstitialLoadSuccess:(MEBaseAdapter *)adapter;

// 展示成功
- (void)adapterInterstitialShowSuccess:(MEBaseAdapter *)adapter;

// 插屏广告加载失败
- (void)adapter:(MEBaseAdapter *)adapter interstitialLoadFailure:(NSError *)error;

// 插屏广告从外部返回原生应用
- (void)adapterInterstitialDismiss:(MEBaseAdapter *)adapter;

// 插屏广告关闭
- (void)adapterInterstitialCloseFinished:(MEBaseAdapter *)adapter;

// 插屏广告被点击
- (void)adapterInterstitialClicked:(MEBaseAdapter *)adapter;

@end

@protocol MEBaseAdapterProtocol <NSObject>
@required
/// 当前广告平台类型
@property (nonatomic, readonly) MEAdAgentType platformType;

/// 信息流 回调代理
@property (nonatomic, weak) id<MEBaseAdapterFeedProtocol> feedDelegate;
/// 激励视频 回调代理
@property (nonatomic, weak) id<MEBaseAdapterVideoProtocol> videoDelegate;
/// 开屏 回调代理
@property (nonatomic, weak) id<MEBaseAdapterSplashProtocol> splashDelegate;
/// 插屏 回调代理
@property (nonatomic, weak) id<MEBaseAdapterInterstitialProtocol> interstitialDelegate;

/// 场景id,即自有posid
@property (nonatomic, copy) NSString *sceneId;
/// 广告位id
@property (nonatomic, copy) NSString *posid;
/// 此次广告的展示类别,有聚合协议传入
@property (nonatomic, assign) NSInteger sortType;
/// 判断是否为拉取广告缓存
@property (nonatomic, assign) BOOL isGetForCache;
/// 判断激励视频是否正在播放,防止同时播放两个激励视频
@property (nonatomic, assign) BOOL isTheVideoPlaying;

+ (instancetype)sharedInstance;

/// 初始化相应广告平台
+ (void)launchAdPlatformWithAppid:(NSString *)appid;

/// 返回对应平台的缩写,穿山甲-tt,广点通-gdt,快手-ks,谷歌-admob,valpub-gdt2
- (NSString *)networkName;

// MARK: - 信息流广告
/// 信息流预加载,并存入缓存
/// @param feedWidth 信息流宽度
/// @param posId 广告位id
- (void)saveFeedCacheWithWidth:(CGFloat)feedWidth
                         posId:(NSString *)posId;

/// 显示信息流视图
/// @param feedWidth 广告位宽度
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(NSString *)posId;

/// 显示信息流视图
/// @param feedWidth 广告位宽度
/// @param displayTime 展示时长
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(NSString *)posId
              withDisplayTime:(NSTimeInterval)displayTime;

/// 移除信息流视图
- (void)removeFeedViewWithPosid:(NSString *)posid;

// MARK: - 信息流自渲染
/// 信息流预加载,并存入缓存
/// @param posId 广告位id
- (void)saveRenderFeedCacheWithPosId:(NSString *)posId;

/// 显示自渲染的信息流视图
- (BOOL)showRenderFeedViewWithPosId:(NSString *)posId;

/// 移除自渲染信息流视图
- (void)removeRenderFeedViewWithPosid:(NSString *)posid;

// MARK: - 激励视频广告

/// 展示激励视频
- (BOOL)showRewardVideoWithPosid:(NSString *)posid;

/// 关闭当前视频
- (void)stopCurrentVideoWithPosid:(NSString *)posid;

// MARK: - 开屏广告

/// 展示开屏页
- (BOOL)showSplashWithPosid:(NSString *)posid;

/// 展示带底部logo的开屏页
- (BOOL)showSplashWithPosid:(NSString *)posid delay:(NSTimeInterval)delay bottomView:(UIView *)view;

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRenderWithPosid:(NSString *)posid;

// MARK: - 插屏广告
/// 展示插屏页
- (BOOL)showInterstitialViewWithPosid:(NSString *)posid showFunnyBtn:(BOOL)showFunnyBtn;
/// 停止插屏
- (void)stopInterstitialWithPosid:(NSString *)posid;

@end

@interface MEBaseAdapter : NSObject<MEBaseAdapterProtocol>

/// 当前广告平台类型
@property (nonatomic, readonly) MEAdAgentType platformType;

/// 信息流 回调代理
@property (nonatomic, weak) id<MEBaseAdapterFeedProtocol> feedDelegate;
/// 激励视频 回调代理
@property (nonatomic, weak) id<MEBaseAdapterVideoProtocol> videoDelegate;
/// 开屏 回调代理
@property (nonatomic, weak) id<MEBaseAdapterSplashProtocol> splashDelegate;
/// 插屏 回调代理
@property (nonatomic, weak) id<MEBaseAdapterInterstitialProtocol> interstitialDelegate;
/// 展示广告的底层控制器
@property (nonatomic, weak) UIViewController *topVC;
/// 误点按钮
@property (nonatomic, strong) MEFunnyButton *funnyButton;

/// 场景id,即自有posid
@property (nonatomic, copy) NSString *sceneId;
/// 广告位id
@property (nonatomic, copy) NSString *posid;
/// 此次广告的展示类别,有聚合协议传入
@property (nonatomic, assign) NSInteger sortType;
/// 判断是否为拉取广告缓存
@property (nonatomic, assign) BOOL isGetForCache;
/// 判断激励视频是否正在播放,防止同时播放两个激励视频
@property (nonatomic, assign) BOOL isTheVideoPlaying;

// MARK: - Tools
/// 获取顶层VC
- (UIViewController *)topVC;

/// md5
- (NSMutableString *)stringMD5:(NSString *)string;

@end
