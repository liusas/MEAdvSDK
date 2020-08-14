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

// MARK: - 开屏广告
/// 展示开屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param delay 开屏广告拉取超时时间,默认 3 秒,注意设置时间少于 3 秒无效
- (void)showSplashAdvTarget:(id)target
                    sceneId:(NSString *)sceneId
                      delay:(NSTimeInterval)delay;

/// 展示开屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param delay 开屏广告拉取超时时间,默认 3 秒,注意设置时间少于 3 秒无效
/// @param finished 展示成功
/// @param failed 展示失败
/// @param close 广告关闭
/// @param click 点击广告
/// @param dismiss 开屏广告被点击后,回到应用
- (void)showSplashAdvTarget:(id)target
                    sceneId:(NSString *)sceneId
                      delay:(NSTimeInterval)delay
                showSuccess:(MEBaseSplashAdFinished)finished
                     failed:(MEBaseSplashAdFailed)failed
                      close:(MEBaseSplashAdCloseClick)close
                      click:(MEBaseSplashAdClick)click
                    dismiss:(MEBaseSplashAdDismiss)dismiss;

/// 展示开屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param delay 开屏广告拉取超时时间,默认 3 秒,注意设置时间少于 3 秒无效
/// @param bottomView 放置logo的view,建议不要超过屏幕高度的25%
/// @param finished 展示成功
/// @param failed 展示失败
/// @param close 广告关闭
/// @param click 点击广告
/// @param dismiss 开屏广告被点击后,回到应用
- (void)showSplashAdvTarget:(id)target
                    sceneId:(NSString *)sceneId
                      delay:(NSTimeInterval)delay
                 bottomView:(UIView *)bottomView
                showSuccess:(MEBaseSplashAdFinished)finished
                     failed:(MEBaseSplashAdFailed)failed
                      close:(MEBaseSplashAdCloseClick)close
                      click:(MEBaseSplashAdClick)click
                    dismiss:(MEBaseSplashAdDismiss)dismiss;

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender:(NSString *)sceneId;

// MARK: - 插屏广告
/// 展示插屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param showFunnyBtn 是否展示误点按钮
- (void)showInterstitialAdvWithTarget:(id)target
                              sceneId:(NSString *)sceneId
                         showFunnyBtn:(BOOL)showFunnyBtn;


/// 展示插屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param showFunnyBtn 是否展示误点按钮
/// @param finished 展示成功
/// @param failed 展示失败
/// @param close 广告关闭
/// @param click 广告点击
/// @param dismiss 插屏广告被点击后,回到应用
- (void)showInterstitialAdvWithTarget:(id)target
                              sceneId:(NSString *)sceneId
                         showFunnyBtn:(BOOL)showFunnyBtn
                             finished:(MEBaseInterstitialAdFinished)finished
                               failed:(MEBaseInterstitialAdFailed)failed
                                close:(MEBaseInterstitialAdCloseClick)close
                                click:(MEBaseInterstitialAdClick)click
                              dismiss:(MEBaseInterstitialAdDismiss)dismiss;

// MARK: - 信息流广告
/**
 *  展示信息流广告
 *  @param bgWidth 必填,信息流背景视图的宽度
 *  @param sceneId 场景Id
 *  @param target 必填,用来承接代理
 */
- (void)showFeedAdvWithBgWidth:(CGFloat)bgWidth sceneId:(NSString *)sceneId Target:(id)target;

/// 展示信息流广告,推荐使用
/// @param bgWidth 信息流广告背景的宽度
/// @param sceneId 场景id
/// @param target 必填,用来承接代理
/// @param finished 广告展示成功
/// @param failed 广告展示失败
/// @param close 广告关闭
/// @param click 点击广告
- (void)showFeedAdvWithBgWidth:(CGFloat)bgWidth
                       sceneId:(NSString *)sceneId
                        Target:(id)target
                      finished:(MEBaseFeedAdFinished)finished
                        failed:(MEBaseFeedAdFailed)failed
                         close:(MEBaseFeedAdCloseClick)close
                         click:(MEBaseFeedAdClick)click;

/// 展示自渲染信息流广告
/// @param sceneId 场景id
/// @param target  必填,用来承接代理
- (void)showRenderFeedAdvWithSceneId:(NSString *)sceneId Target:(id)target;

/// 展示自渲染信息流广告,推荐使用
/// @param sceneId 场景id
/// @param target  必填,用来承接代理
/// @param finished 广告展示成功
/// @param failed 广告展示失败
/// @param close 广告关闭
/// @param click 点击广告
- (void)showRenderFeedAdvWithSceneId:(NSString *)sceneId
                              Target:(id)target
                            finished:(MEBaseFeedAdFinished)finished
                              failed:(MEBaseFeedAdFailed)failed
                               close:(MEBaseFeedAdCloseClick)close
                               click:(MEBaseFeedAdClick)click;

// MARK: - 激励视频广告
/**
 *  展示激励视频广告, 目前只有穿山甲激励视频
 *  @param sceneId 场景Id,在MEAdBaseManager.h中可查
 *  @param target 必填,接收回调
*/
- (void)showRewardedVideoWithSceneId:(NSString *)sceneId
                              target:(id)target;

/// 展示激励视频广告, 目前只有穿山甲激励视频
/// @param sceneId 场景Id,在MEAdBaseManager.h中可查
/// @param target 必填,接收回调
/// @param finished 视频广告展示成功
/// @param failed 视频广告展示失败
/// @param finishPlay 视频广告播放完毕
/// @param close 视频广告关闭
/// @param click 点击视频广告
- (void)showRewardedVideoWithSceneId:(NSString *)sceneId
                              target:(id)target
                            finished:(MEBaseRewardVideoFinish)finished
                              failed:(MEBaseRewardVideoFailed)failed
                          finishPlay:(MEBaseRewardVideoFinishPlay)finishPlay
                               close:(MEBaseRewardVideoCloseClick)close
                               click:(MEBaseRewardVideoClick)click;


/// 停止当前播放的视频
- (void)stopRewardedVideo;
@end
