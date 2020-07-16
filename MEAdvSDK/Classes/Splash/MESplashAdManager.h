//
//  MESplashAdManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/27.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"

typedef void(^LoadSplashAdFinished)(void);   // 广告展示成功
typedef void(^LoadSplashAdFailed)(NSError *error);    // 广告展示失败
typedef void(^LoadSplashAdCloseClick)(void);          // 广告被关闭
typedef void(^LoadSplashAdClick)(void);               // 广告被点击
typedef void(^LoadSplashAdDismiss)(void);               // 广告被点击后,回到应用
@interface MESplashAdManager : NSObject

/// 广告关闭block
@property (nonatomic, copy) LoadSplashAdCloseClick closeBlock;
/// 广告被点击block
@property (nonatomic, copy) LoadSplashAdClick clickBlock;
/// 广告被点击后,回到应用
@property (nonatomic, copy) LoadSplashAdDismiss clickThenDismiss;

/// 记录此次返回的广告是哪个平台的
@property (nonatomic, assign) MEAdAgentType currentAdPlatform;

+ (instancetype)shareInstance;

/// 展示开屏广告
- (void)showSplashAdvWithSceneId:(NSString *)sceneId
                           delay:(NSTimeInterval)delay
                        Finished:(LoadSplashAdFinished)finished
                          failed:(LoadSplashAdFailed)failed;

/// 展示开屏广告带logo
- (void)showSplashAdvWithSceneId:(NSString *)sceneId
                           delay:(NSTimeInterval)delay
                      bottomView:(UIView *)bottomView
                        Finished:(LoadSplashAdFinished)finished
                          failed:(LoadSplashAdFailed)failed;

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender:(NSString *)sceneId;
@end
