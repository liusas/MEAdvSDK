//
//  MEBannerManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/9/9.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^BannerViewReturnBlock)(UIView *bannerView);       // banner 视图回调
typedef void(^LoadBannerAdFinished)(void);        // 广告加载成功
typedef void(^ShowBannerAdFinished)(void);        // 广告展示成功
typedef void(^LoadBannerAdFailed)(NSError *error);// 广告展示失败
typedef void(^BannerAdCloseClick)(void);          // 广告被关闭
typedef void(^BannerAdClick)(void);               // 广告被点击


@interface MEBannerManager : NSObject

@property (nonatomic, copy) ShowBannerAdFinished showFinishBlock;
/// 广告关闭block
@property (nonatomic, copy) BannerAdCloseClick closeBlock;
/// 广告被点击block
@property (nonatomic, copy) BannerAdClick clickBlock;

/// 记录此次返回的广告是哪个平台的
@property (nonatomic, assign) MEAdAgentType currentAdPlatform;


/// 展示 banner 广告
/// @param size 广告所占大小
/// @param sceneId 广告场景 id
/// @param rootVC 用于跳转的控制器
/// @param interval 刷新间隔
/// @param finished 加载成功回调
/// @param failed 失败回调
- (void)showBannerViewWithSize:(CGSize)size
                           sceneId:(NSString *)sceneId
                            rootVC:(UIViewController *)rootVC
                   refreshInterval:(NSTimeInterval)interval
                        bannerView:(BannerViewReturnBlock)bannerReturnBlock
                          finished:(LoadBannerAdFinished)finished
                            failed:(LoadBannerAdFailed)failed;

@end

NS_ASSUME_NONNULL_END
