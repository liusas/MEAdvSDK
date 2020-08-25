//
//  XFPlayer.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/10.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const kXFPlayerStateChangedNotification;
FOUNDATION_EXPORT NSString *const kXFPlayerProgressChangedNotification;
FOUNDATION_EXPORT NSString *const kXFPlayerLoadProgressChangedNotification;

//播放器的几种状态
typedef NS_ENUM(NSInteger, XFPlayerState) {
    TBPlayerStateBuffering = 1,
    TBPlayerStatePlaying   = 2,
    TBPlayerStateStopped   = 3,
    TBPlayerStatePause     = 4
};
@protocol MobiXFPlayerDelegate <NSObject>

- (void)playWithCurrent:(CGFloat)current totalDuration:(CGFloat)tatalDuration playProgress:(CGFloat )playProgress;

@end

@interface MobiXFPlayer : NSObject

@property (nonatomic, strong) AVPlayer       *player;
@property (nonatomic, readonly) XFPlayerState state;
@property (nonatomic, readonly) CGFloat       loadedProgress;   //缓冲进度
@property (nonatomic, readonly) CGFloat       duration;         //视频总时间
@property (nonatomic, readonly) CGFloat       current;          //当前播放时间
@property (nonatomic, readonly) CGFloat       progress;         //播放进度 0~1
@property (nonatomic          ) BOOL          stopWhenAppDidEnterBackground;// default is YES
@property (nonatomic, assign) BOOL isMuteds;

@property (nonatomic, copy) NSURL *contentURL;

@property (nonatomic, weak) id<MobiXFPlayerDelegate>delegate;

+ (instancetype)sharedInstance;
- (void)playWithUrl:(NSURL *)url showView:(UIView *)showView showType:(NSInteger)type;
- (void)seekToTime:(CGFloat)seconds;

- (void)resume;
- (void)pause;
- (void)stop;

- (void)fullScreen;  //全屏
- (void)halfScreen;   //半屏

@end
