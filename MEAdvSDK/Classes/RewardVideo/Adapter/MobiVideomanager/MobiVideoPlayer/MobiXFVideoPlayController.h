//
//  XFVideoPlayController.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/10.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobiAdVideoBaseClass.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  播放视频进度类型
 */
typedef NS_ENUM(NSInteger,MobiVideoPlayProgressType) {
    MobiVideoPlayFirst_Quarter_Play      = 1,// 1/4进度
    MobiVideoPlayMid_play      = 2,//1/2进度
    MobiVideoPlayThird_Quarter_Play      = 3,// 3/4进度
    MobiVideoPlayFinish_Play  = 4,// 播放完成
};

@protocol MobiXFVideoPlayControllerDelegate <NSObject>

@optional

/// 视频广告加载成功
- (void)rewardedVideoDidLoadAdSuccess;

/// 视频广告加载失败
- (void)rewardedVideoDidLoadAdFailed;

/// 视频加载成功,但是已无效,调用此方法
- (void)rewardedVideoDidLoadWithExpire;

/// 视频已经开始播放,但是没有播放完整(归为播放失败或者视频失效)
/// 当视图播放一个激励视频,但激励视频并没有播放成功时,调用此方法
/// 另一个调用此方法的原因是,要播放视频时,该视频失效了
- (void)rewardedVideoPlayFailedWithNoComplete;

/// 视频展现成功
- (void)rewardedVideoShowSuccess;

/// 视频展现失败
- (void)rewardedVideoShowFailed;

/// 视频广告关闭
- (void)rewardedVideoCloseClick;

/// 视频广告被点击
- (void)rewardedVideoDownloadClick;

/// 视频播放进度上报
-(void)mobiVideoPlayProgress:(MobiVideoPlayProgressType)progressType;
@end

@interface MobiXFVideoPlayController : UIViewController

@property (nonatomic, weak) id<MobiXFVideoPlayControllerDelegate> delegate;
///播放的样式 1.横屏播放 2.竖屏播放
@property (nonatomic, assign) NSInteger playType;
/// 视频播放URL
@property (nonatomic, strong) NSURL *contenURL;

@property (nonatomic, assign) MobiVideoPlayProgressType *progressType;

@property (nonatomic, strong) MobiAdVideoBaseClass *videoDataBase;

@end

NS_ASSUME_NONNULL_END
