//
//  MEFeedAdManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/8.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CacheLoadAdFinished)(void);   // 广告预加载成功
typedef void(^CacheLoadAdFailed)(NSError *error);   // 广告预加载失败
typedef void(^LoadAdFinished)(UIView *feedView);   // 广告展示成功
typedef void(^LoadAdFailed)(NSError *error);    // 广告展示失败
typedef void(^LoadAdCloseClick)(void);          // 广告被关闭
typedef void(^LoadAdClick)(void);               // 广告被点击

@interface MEFeedAdManager : NSObject

/// 广告关闭block
@property (nonatomic, copy) LoadAdCloseClick closeBlock;
/// 广告被点击block
@property (nonatomic, copy) LoadAdClick clickBlock;

/// 记录此次返回的广告是哪个平台的
@property (nonatomic, assign) MEAdAgentType currentAdPlatform;

+ (instancetype)shareInstance;

// MARK: - 信息流
/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
/// @param sceneId 场景Id,在MEAdBaseManager.h中可查
- (void)showFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed;

/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
/// @param sceneId 场景Id,在MEAdBaseManager.h中可查
/// @param displayTime 展示时长
- (void)showFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
              withDisplayTime:(NSTimeInterval)displayTime
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed;

// MARK: - 信息流自渲染
/// 显示自渲染的信息流视图
- (void)showRenderFeedViewWithSceneId:(NSString *)sceneId
                             finished:(LoadAdFinished)finished
                               failed:(LoadAdFailed)failed;

@end

NS_ASSUME_NONNULL_END
