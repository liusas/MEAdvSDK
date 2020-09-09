//
//  MEAdBaseManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"

@class MEAdBaseManager;

/// 配置请求并初始化广告平台成功的block
typedef void(^RequestAndInitFinished)(BOOL success);

@interface MEAdBaseManager : NSObject

// MARK: - 广告平台的APPID
// 目前集成了穿山甲,广点通,快手及谷歌,谷歌需要从info.plist中配置GADApplicationIdentifier
/// 开屏广告代理
@property (nonatomic, weak) id<MESplashDelegate> splashDelegate;
/// 信息流广告代理
@property (nonatomic, weak) id<MEFeedViewDelegate> feedDelegate;
/// 激励视频广告代理
@property (nonatomic, weak) id<MERewardVideoDelegate> rewardVideoDelegate;
/// 插屏广告代理
@property (nonatomic, weak) id<MEInterstitialDelegate> interstitialDelegate;
/// 全屏广告代理
@property (nonatomic, weak) id<MEFullscreenVideoDelegate> fullscreenVideoDelegate;
/// 记录此次返回的广告是哪个平台的
@property (nonatomic, assign) MEAdAgentType currentAdPlatform;
/// 广告平台是否已经初始化
@property (nonatomic, assign, readonly) BOOL isPlatformInit;

/// singleton
+ (instancetype)sharedInstance;

/// 从服务端请求广告平台配置信息,主要是"sceneId": "posid"这样的键值对,在调用展示广告时,我们只需传入相应的sceneId,由SDK内部根据配置和广告优先级等因素去分配由哪个平台展示广告,
/// 注意:要在info.plist文件中配置谷歌的appid,即使不接入谷歌广告也要传一个
/// key:value对应 GADApplicationIdentifier : ca-app-pub-3940256099942544~1458002511
/// UUID供上报分析数据使用,可不传,默认弹出广点通测试版广告,不会产生收益
/// @param appid 聚合广告平台id
/// @param finished 完成初始化的回调
+ (void)launchWithAppID:(NSString *)appid finished:(RequestAndInitFinished)finished;

// MARK: - ---------------------------------v0.1.9版本接口调整---------------------------------
// MARK: - 开屏
/// 预加载开屏广告
- (void)preloadSplashWithSceneId:(NSString *)sceneId delegate:(id)delegate;
/// 展示开屏广告
/// @param delegate 接收代理的类
/// @param sceneId 场景id
/// @param delay 开屏广告拉取超时时间,默认 3 秒,注意设置时间少于 3 秒无效
/// @param bottomView 放置logo的view,建议不要超过屏幕高度的25%
- (void)loadAndShowSplashAdSceneId:(NSString *)sceneId
                          delegate:(id)delegate
                             delay:(NSTimeInterval)delay
                        bottomView:(UIView *)bottomView;

/// 展示开屏广告的 block 回调

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender:(NSString *)sceneId;

// MARK: - 信息流
/// 展示信息流广告
/// @param size 信息流广告期望大小,高度可传 0,广告平台会根据宽度自适应信息流高度
/// @param sceneId 广告位 id,需要在摩邑诚开发者平台注册
/// @param delegate 必填,用来接收代理
/// @param count 请求数量,最大值不应超过三个
- (void)loadFeedAdWithSize:(CGSize)size
                   sceneId:(NSString *)sceneId
                  delegate:(id)delegate
                     count:(NSInteger)count;

// MARK: - 激励视频
/// 加载激励视频广告
/// @param sceneId 广告位 id
/// @param delegate 必填,用来接收代理
- (void)loadRewardedVideoWitSceneId:(NSString *)sceneId delegate:(id)delegate;
/// 展示激励视频广告
/// @param rootVC 用于 present 激励视频 VC
/// @param sceneId 广告位 id
- (void)showRewardedVideoFromViewController:(UIViewController *)rootVC sceneId:(NSString *)sceneId;
/// 停止当前激励视频
- (void)stopRewardedVideo:(NSString *)sceneId;
/// 检测广告位下的广告是否有效
/// @param sceneId 广告位 id
- (BOOL)hasRewardedVideoAvailableWithSceneId:(NSString *)sceneId;

// MARK: - 全屏视频
/// 加载全屏视频广告
/// @param sceneId 广告位 id
/// @param delegate 必填,用来接收代理
- (void)loadFullscreenVideoWithSceneId:(NSString *)sceneId delegate:(id)delegate;
/// 展示全屏视频广告
/// @param rootVC 用于 present 激励视频 VC
/// @param sceneId 广告位 id
- (void)showFullscreenVideoFromViewController:(UIViewController *)rootVC sceneId:(NSString *)sceneId;
/// 关闭全屏视频广告
/// @param sceneId 广告位 id
- (void)stopFullscreenVideo:(NSString *)sceneId;
/// 当前广告位下是否有有效的全屏视频广告
- (BOOL)hasFullscreenVideoAvailableWithSceneId:(NSString *)sceneId;

// MARK: - 插屏
/// 加载插屏广告
/// @param sceneId 广告位 id
/// @param delegate 必填,用来接收代理
- (void)loadInterstitialWithSceneId:(NSString *)sceneId
                           delegate:(id)delegate;
/// 展示插屏频广告
/// @param rootVC 用于 present 插屏 VC
/// @param sceneId 广告位 id
- (void)showInterstitialFromViewController:(UIViewController *)rootVC
                                   sceneId:(NSString *)sceneId;

/// 关掉当前的插屏
/// @param sceneId 广告位 id
- (void)stopInterstitialRender:(NSString *)sceneId;

/// 检测广告位下的广告是否有效
/// @param sceneId 广告位 id
- (BOOL)hasInterstitialAvailableWithSceneId:(NSString *)sceneId;
@end
