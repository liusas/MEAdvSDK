//
//  MEAdBaseManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"
#import "MEGDTCustomView.h"

@class MEAdBaseManager;

@protocol MESplashDelegate <NSObject>
@optional
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
/// 信息流广告展现成功
- (void)feedViewShowSuccess:(MEAdBaseManager *)adManager feedView:(UIView *)feedView;

/// 信息流广告展现失败
- (void)feedViewShowFeedViewFailure:(NSError *)error;

/// 信息流广告被关闭
- (void)feedViewCloseClick:(MEAdBaseManager *)adManager;

/// 信息流广告被点击
- (void)feedViewClicked:(MEAdBaseManager *)adManager;

@end

@protocol MERewardVideoDelegate <NSObject>
@optional
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
/// 配置请求并初始化广告平台成功的block
typedef void(^RequestAndInitFinished)(BOOL success);

@interface MEAdBaseManager : NSObject

@property (nonatomic, weak) id<MESplashDelegate> splashDelegate;
@property (nonatomic, weak) id<MEFeedViewDelegate> feedDelegate;
@property (nonatomic, weak) id<MERewardVideoDelegate> rewardVideoDelegate;
@property (nonatomic, weak) id<MEInterstitialDelegate> interstitialDelegate;
/// 记录此次返回的广告是哪个平台的
@property (nonatomic, assign) MEAdAgentType currentAdPlatform;
/// 广告平台是否已经初始化
@property (nonatomic, assign, readonly) BOOL isPlatformInit;


+ (instancetype)sharedInstance;

/// 从服务端请求广告平台配置信息
/// @param adRequestUrl 服务端的请求baseUrl
- (void)requestPlatformConfigWithUrl:(NSString *)adRequestUrl
                              logUrl:(NSString *)logUrl
                            deviceId:(NSString *)deviceId
                            finished:(RequestAndInitFinished)finished;

/// 初始化广告平台, 注意需要用真机测试
/// @param BUADAppId 穿山甲Appid
/// @param GDTAppId 广点通Appid
+ (void)lanuchAdPlatformWithBUADAppId:(NSString *)BUADAppId
                             GDTAppId:(NSString *)GDTAppId
                              KSAppId:(NSString *)ksAppid;

// MARK: - 开屏广告
/// 展示开屏广告
- (void)showSplashAdvTarget:(id)target sceneId:(NSString *)sceneId;

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender;

// MARK: - 插屏广告
/// 展示插屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param showFunnyBtn 是否展示误点按钮
- (void)showInterstitialAdvWithTarget:(id)target
                              sceneId:(NSString *)sceneId
                         showFunnyBtn:(BOOL)showFunnyBtn;

// MARK: - 信息流广告
/// 缓存信息流广告
/// @param feedModelArr MEAdFeedModel实例的数组,包含信息流宽度和场景id
- (void)saveFeedAdvToCacheWithFeedModelArr:(NSArray <MEAdFeedModel *>*)feedModelArr;

/**
 *  展示信息流广告
 *  @param bgWidth 必填,信息流背景视图的宽度
 *  @param sceneId 场景Id
 *  @param target 必填,用来承接代理
 */
- (void)showFeedAdvWithBgWidth:(CGFloat)bgWidth sceneId:(NSString *)sceneId Target:(id)target;

/// 缓存自渲染信息流广告
/// @param feedModelArr MEAdFeedModel实例的数组,包含信息流宽度和场景id
- (void)saveRenderFeedAdvToCacheWithFeedModelArr:(NSArray <MEAdFeedModel *>*)feedModelArr;

/// 展示自渲染信息流广告
/// @param sceneId 场景id
/// @param target  必填,用来承接代理
- (void)showRenderFeedAdvWithSceneId:(NSString *)sceneId Target:(id)target;

// MARK: - 激励视频广告
/**
 *  展示激励视频广告, 目前只有穿山甲激励视频
 *  @param sceneId 场景Id,在MEAdBaseManager.h中可查
 *  @param target 必填,接收回调
*/
- (void)showRewardedVideoWithSceneId:(NSString *)sceneId target:(id)target;


/// 停止当前播放的视频
- (void)stopRewardedVideo;
@end
