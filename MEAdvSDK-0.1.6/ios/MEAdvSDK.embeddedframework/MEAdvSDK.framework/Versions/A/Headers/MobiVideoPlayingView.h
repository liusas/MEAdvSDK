//
//  VideoPlayingView.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/30.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobiVideoEndModel.h"
#import "MobiVideoAdButton.h"
#import "MobiLaunchAdImageView.h"


@protocol MobiVideoPlayingViewDelegate <NSObject>
/// 跳过
- (void)videoPlayingJumpClick;
/// 下载
- (void)videoPlayingDownloadLClick;
/// 是否静音
- (void)videoPlayingMutedClick:(BOOL)isMuted;

@end

@interface MobiVideoPlayingView : UIView

@property (nonatomic, weak) id<MobiVideoPlayingViewDelegate>delegate;
@property (nonatomic, strong) MobiVideoEndModel *model;

- (instancetype)init;

- (void)showViewWithModel:(MobiVideoEndModel *)model;

- (void)startVideoMobiSkipType:(MobiSkipType)skipType countdownTime:(CGFloat)duration;

- (void)setLabelTitle:(NSString *)str skipType:(MobiSkipType)skipType;
@end

