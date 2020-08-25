//
//  MEFullscreenManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/8/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LoadFullscreenVideoFinish)(void);             // 视频广告加载成功
typedef void(^ShowFullscreenVideoFinish)(void);             // 视频广告展示成功
typedef void(^FullscreenVideoDidDownload)(void);            // 视频广告缓存成功
typedef void(^FullscreenVideoFailed)(NSError *error);       // 视频广告展示失败
typedef void(^FullscreenVideoFinishPlay)(void);             // 视频广告播放完毕
typedef void(^FullscreenVideoClick)(void);                  // 点击视频广告
typedef void(^FullscreenVideoCloseClick)(void);             // 视频广告被关闭
typedef void(^FullscreenVideoClickSkip)(void);              // 视频广告点击了跳过

@interface MEFullscreenManager : NSObject

/// 视频广告展示完成
@property (nonatomic, copy) ShowFullscreenVideoFinish showFinish;
/// 视频广告已经下载完成
@property (nonatomic, copy) FullscreenVideoDidDownload didDownloadBlock;
/// 视频广告被关闭block
@property (nonatomic, copy) FullscreenVideoCloseClick closeBlock;
/// 点击视频广告block
@property (nonatomic, copy) FullscreenVideoClick clickBlock;
/// 视频广告播放完毕block
@property (nonatomic, copy) FullscreenVideoFinishPlay finishPlayBlock;
/// 视频广告点击了跳过block
@property (nonatomic, copy) FullscreenVideoClickSkip skipBlock;

+ (instancetype)shareInstance;

/// 加载激励视频
- (void)loadFullscreenVideoWithSceneId:(NSString *)sceneId
                            finished:(LoadFullscreenVideoFinish)finished
                              failed:(FullscreenVideoFailed)failed;

/// 展示激励视频
- (void)showFullscreenVideoFromViewController:(UIViewController *)rootVC
                                    sceneId:(NSString *)sceneId;

/// 关闭当前视频
- (void)stopFullscreenVideoWithSceneId:(NSString *)sceneId;
/// 是否有有效的全屏视频
- (BOOL)hasFullscreenVideoAvailableWithSceneId:(NSString *)sceneId;

@end

NS_ASSUME_NONNULL_END
