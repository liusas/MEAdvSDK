//
//  MEInterstitialAdManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/12/13.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^LoadInterstitialAdFinished)(void);            // 广告加载成功
typedef void(^ShowInterstitialAdFinished)(void);            // 广告展示成功
typedef void(^LoadInterstitialAdFailed)(NSError *error);    // 广告展示失败
typedef void(^LoadInterstitialAdCloseClick)(void);          // 广告被关闭
typedef void(^LoadInterstitialAdClick)(void);               // 广告被点击
typedef void(^LoadInterstitialAdDismiss)(void);             // 广告被点击后,回到应用

@interface MEInterstitialAdManager : NSObject

@property (nonatomic, copy) ShowInterstitialAdFinished showFinishBlock;
/// 广告关闭block
@property (nonatomic, copy) LoadInterstitialAdCloseClick closeBlock;
/// 广告被点击block
@property (nonatomic, copy) LoadInterstitialAdClick clickBlock;
/// 广告被点击后,回到应用
@property (nonatomic, copy) LoadInterstitialAdDismiss clickThenDismiss;

/// 记录此次返回的广告是哪个平台的
@property (nonatomic, assign) MEAdAgentType currentAdPlatform;

+ (instancetype)shareInstance;

/// 加载插屏页
- (void)loadInterstitialWithSceneId:(NSString *)sceneId
                           finished:(LoadInterstitialAdFinished)finished
                             failed:(LoadInterstitialAdFailed)failed;
                            
/// 展示插屏页
- (void)showInterstitialFromViewController:(UIViewController *)rootVC sceneId:(NSString *)sceneId;

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopInterstitialRenderWithSceneId:(NSString *)sceneId;
- (BOOL)hasInterstitialAvailableWithSceneId:(NSString *)sceneId;
@end

NS_ASSUME_NONNULL_END
