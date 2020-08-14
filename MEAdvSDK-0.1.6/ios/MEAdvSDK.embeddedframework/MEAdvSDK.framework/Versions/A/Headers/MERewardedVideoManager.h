//
//  MERewardedVideoManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LoadRewardVideoFinish)(void);             // 视频广告展示成功
typedef void(^LoadRewardVideoFailed)(NSError *error);   // 视频广告展示失败
typedef void(^RewardVideoFinishPlay)(void);             // 视频广告播放完毕
typedef void(^LoadRewardVideoClick)(void);              // 点击视频广告
typedef void(^LoadRewardVideoCloseClick)(void);         // 视频广告被关闭

@interface MERewardedVideoManager : NSObject

/// 视频广告被关闭block
@property (nonatomic, copy) LoadRewardVideoCloseClick closeBlock;
/// 点击视频广告block
@property (nonatomic, copy) LoadRewardVideoClick clickBlock;
/// 视频广告播放完毕block
@property (nonatomic, copy) RewardVideoFinishPlay finishPlayBlock;

+ (instancetype)shareInstance;

/// 展示激励视频
- (void)showRewardVideoWithSceneId:(NSString *)sceneId
                          Finished:(LoadRewardVideoFinish)finished
                            failed:(LoadRewardVideoFailed)failed;
/// 关闭当前视频
- (void)stopCurrentVideo;

@end

NS_ASSUME_NONNULL_END
