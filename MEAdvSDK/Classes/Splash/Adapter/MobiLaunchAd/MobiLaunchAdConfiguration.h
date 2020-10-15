//
//  MobiLaunchAdConfiguration.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "MobiLaunchAdConst.h"
#import "MobiLaunchAdButton.h"
#import "MobiLaunchAdImageManager.h"


NS_ASSUME_NONNULL_BEGIN

/** 显示完成动画时间默认时间 */
static CGFloat const showFinishAnimateTimeDefault = 0.8;

/** 显示完成动画类型 */
typedef NS_ENUM(NSInteger , MobiShowFinishAnimate) {
    /** 无动画 */
    MobiShowFinishAnimateNone = 1,
    /** 普通淡入(default) */
    MobiShowFinishAnimateFadein = 2,
    /** 放大淡入 */
    MobiShowFinishAnimateLite = 3,
    /** 左右翻转(类似网易云音乐) */
    MobiShowFinishAnimateFlipFromLeft = 4,
    /** 下上翻转 */
    MobiShowFinishAnimateFlipFromBottom = 5,
    /** 向上翻页 */
    MobiShowFinishAnimateCurlUp = 6,
};

//MARK: 公共的属性
@interface MobiLaunchAdConfiguration : NSObject

/** 停留时间(default 5 ,单位:秒) */
@property(nonatomic,assign) NSInteger duration;

/** 跳过按钮类型(default SkipTypeTimeText) */
@property(nonatomic,assign) MobiSkipType skipButtonType;

/** 显示完成动画(default ShowFinishAnimateFadein) */
@property(nonatomic,assign) MobiShowFinishAnimate showFinishAnimate;

/** 显示完成动画时间(default 0.8 , 单位:秒) */
@property(nonatomic,assign) CGFloat showFinishAnimateTime;

/** 设置开屏广告的frame(default [UIScreen mainScreen].bounds) */
@property (nonatomic,assign) CGRect frame;

/** 点击打开页面参数 */
@property (nonatomic, strong) id openModel;

/** 自定义跳过按钮(若定义此视图,将会自动替换系统跳过按钮) */
@property(nonatomic,strong) UIView *customSkipView;

/** 子视图(若定义此属性,这些视图将会被自动添加在广告视图上,frame相对于window) */
@property(nonatomic,copy,nullable) NSArray<UIView *> *subViews;

@end

//MARK: 图片广告相关
@interface MobiLaunchImageAdConfiguration : MobiLaunchAdConfiguration

/** image本地图片名(jpg/gif图片请带上扩展名)或网络图片URL string */
@property(nonatomic,copy) NSString *imageNameOrURLString;

/** 图片广告缩放模式(default UIViewContentModeScaleToFill) */
@property(nonatomic,assign) UIViewContentMode contentMode;

/** 缓存机制(default MobiLaunchImageDefault) */
@property(nonatomic,assign) MobiLaunchAdImageOptions imageOption;

/** 设置GIF动图是否只循环播放一次(YES:只播放一次,NO:循环播放,default NO,仅对动图设置有效) */
@property (nonatomic, assign) BOOL GIFImageCycleOnce;

/** 展示开屏广告的根视图 */
@property(nonatomic, strong) UIWindow *window;


+ (MobiLaunchImageAdConfiguration *)defaultConfiguration;

@end

//MARK: 视频广告相关
@interface MobiVideoAdConfiguration : MobiLaunchAdConfiguration

/** video本地名或网络链接URL string */
@property(nonatomic,copy)NSString *videoNameOrURLString;

/** 视频缩放模式(default MPMovieScalingModeAspectFill) */
@property(nonatomic,assign)MPMovieScalingMode scalingMode MobiLaunchAdDeprecated("请使用videoGravity");

/** 视频缩放模式(default AVLayerVideoGravityResizeAspectFill) */
@property (nonatomic, copy) AVLayerVideoGravity videoGravity;

/** 设置视频是否只循环播放一次(YES:只播放一次,NO循环播放,default NO) */
@property (nonatomic, assign) BOOL videoCycleOnce;

/** 是否关闭音频(default NO) */
@property (nonatomic, assign) BOOL muted;

+(MobiVideoAdConfiguration *)defaultConfiguration;

@end

NS_ASSUME_NONNULL_END

