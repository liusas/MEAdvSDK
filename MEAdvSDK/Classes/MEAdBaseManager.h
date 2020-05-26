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

/// 配置请求并初始化广告平台成功的block
typedef void(^RequestAndInitFinished)(BOOL success);

@interface MEAdBaseManager : NSObject

// MARK: - 广告平台的APPID
// 目前集成了穿山甲,广点通,快手及谷歌,谷歌需要从info.plist中配置GADApplicationIdentifier
/// 穿山甲Appid
@property (nonatomic, copy) NSString *BUADAPPId;
/// 广点通Appid
@property (nonatomic, copy) NSString *GDTAPPId;
/// 快手Appid
@property (nonatomic, copy) NSString *KSAppId;
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
/// 调用此方法的前提需要先给BUADAPPId,GDTAPPId,KSAppId传值,以及在info.plist文件中配置谷歌的GADApplicationIdentifier
/// 前期测试时可以不穿UUID,默认弹出广点通测试版广告,不会产生收益
/// @param adRequestUrl 请求广告配置的url
/// @param logUrl 上报广告数据的url
- (void)requestPlatformConfigWithUrl:(NSString *)adRequestUrl
                              logUrl:(NSString *)logUrl
                            deviceId:(NSString *)deviceId
                            finished:(RequestAndInitFinished)finished;

/// 从服务端请求广告平台配置信息,主要是"sceneId": "posid"这样的键值对,在调用展示广告时,我们只需传入相应的sceneId,由SDK内部根据配置和广告优先级等因素去分配由哪个平台展示广告
/// 调用此方法的前提需要先给BUADAPPId,GDTAPPId,KSAppId传值,以及在info.plist文件中配置谷歌的GADApplicationIdentifier
/// 前期测试时可以不穿UUID,默认弹出广点通测试版广告,不会产生收益
/// @param adRequestUrl 请求广告配置的url
/// @param logUrl 上报广告数据的url
/// @param deviceId 设备id,一般是使用存到钥匙串中的uuid来作为用户的唯一标识
/// @param buadAppID 在穿山甲平台申请的穿山甲Appid,若不传,默认只初始化穿山甲平台的测试Appid,展示测试版穿山甲广告
/// @param gdtAppID 广点通Appid,若不传,默认只初始化穿山甲平台的测试Appid,展示测试版穿山甲广告
/// @param ksAppID 快手Appid,若不传,默认只初始化穿山甲平台的测试Appid,展示测试版穿山甲广告
/// @param finished 初始化完成的回调
- (void)requestPlatformConfigWithUrl:(NSString *)adRequestUrl
                              logUrl:(NSString *)logUrl
                            deviceId:(NSString *)deviceId
                           BUADAPPId:(NSString *)buadAppID
                            GDTAPPId:(NSString *)gdtAppID
                             KSAppId:(NSString *)ksAppID
                            finished:(RequestAndInitFinished)finished;

/// 初始化广告平台, 注意需要用真机测试
/// @param BUADAppId 穿山甲Appid
/// @param GDTAppId 广点通Appid
+ (void)lanuchAdPlatformWithBUADAppId:(NSString *)BUADAppId
                             GDTAppId:(NSString *)GDTAppId
                              KSAppId:(NSString *)ksAppid;

// MARK: - 开屏广告
/// 展示开屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
- (void)showSplashAdvTarget:(id)target sceneId:(NSString *)sceneId;

/// 展示开屏广告
/// @param target 接收代理的类
/// @param sceneId 场景id
/// @param finished 展示成功
/// @param failed 展示失败
/// @param close 广告关闭
/// @param click 点击广告
/// @param dismiss 开屏广告被点击后,回到应用
- (void)showSplashAdvTarget:(id)target sceneId:(NSString *)sceneId
                showSuccess:(MEBaseSplashAdFinished)finished
                     failed:(MEBaseSplashAdFailed)failed
                      close:(MEBaseSplashAdCloseClick)close
                      click:(MEBaseSplashAdClick)click
                    dismiss:(MEBaseSplashAdDismiss)dismiss;

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

/// 展示信息流广告
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

/// 缓存自渲染信息流广告
/// @param feedModelArr MEAdFeedModel实例的数组,包含信息流宽度和场景id
- (void)saveRenderFeedAdvToCacheWithFeedModelArr:(NSArray <MEAdFeedModel *>*)feedModelArr;

/// 展示自渲染信息流广告
/// @param sceneId 场景id
/// @param target  必填,用来承接代理
- (void)showRenderFeedAdvWithSceneId:(NSString *)sceneId Target:(id)target;

/// 展示自渲染信息流广告
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
