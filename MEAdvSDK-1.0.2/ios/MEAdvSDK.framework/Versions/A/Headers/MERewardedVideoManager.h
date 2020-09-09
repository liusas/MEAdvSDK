//
//  MERewardedVideoManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LoadRewardVideoFinish)(void);             // 视频广告加载成功
typedef void(^ShowRewardVideoFinish)(void);             // 视频广告展示成功
typedef void(^RewardVideoDidDownload)(void);            // 视频广告缓存成功
typedef void(^LoadRewardVideoFailed)(NSError *error);   // 视频广告展示失败
typedef void(^RewardVideoFinishPlay)(void);             // 视频广告播放完毕
typedef void(^LoadRewardVideoClick)(void);              // 点击视频广告
typedef void(^LoadRewardVideoCloseClick)(void);         // 视频广告被关闭

@interface MERewardedVideoManager : NSObject

@property (nonatomic, copy) ShowRewardVideoFinish showFinish;
@property (nonatomic, copy) RewardVideoDidDownload didDownloadBlock;
/// 视频广告被关闭block
@property (nonatomic, copy) LoadRewardVideoCloseClick closeBlock;
/// 点击视频广告block
@property (nonatomic, copy) LoadRewardVideoClick clickBlock;
/// 视频广告播放完毕block
@property (nonatomic, copy) RewardVideoFinishPlay finishPlayBlock;

+ (instancetype)shareInstance;

/// 加载激励视频
- (void)loadRewardedVideoWithSceneId:(NSString *)sceneId
                            finished:(LoadRewardVideoFinish)finished
                              failed:(LoadRewardVideoFailed)failed;

/// 展示激励视频
- (void)showRewardedVideoFromViewController:(UIViewController *)rootVC
                                    sceneId:(NSString *)sceneId;

/// 关闭当前视频
- (void)stopCurrentVideoWithSceneId:(NSString *)sceneId;
- (BOOL)hasRewardedVideoAvailableWithSceneId:(NSString *)sceneId;

@end

NS_ASSUME_NONNULL_END
