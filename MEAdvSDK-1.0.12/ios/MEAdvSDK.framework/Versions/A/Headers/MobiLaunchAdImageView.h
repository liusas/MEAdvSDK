//
//  MobiLaunchAdImageView.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "FLAnimatedImageView.h"
#import "MobiLaunchAdConst.h"
#import "MobiLaunchAdImageManager.h"

#if __has_include(<FLAnimatedImage/FLAnimatedImage.h>)
    #import <FLAnimatedImage/FLAnimatedImage.h>
#else
    #import "FLAnimatedImage.h"
#endif

#if __has_include(<FLAnimatedImage/FLAnimatedImageView.h>)
    #import <FLAnimatedImage/FLAnimatedImageView.h>
#else
    #import "FLAnimatedImageView.h"
#endif

//MARK: image

@interface MobiLaunchAdImageView : FLAnimatedImageView

//@property (nonatomic, copy) void(^ _Nullable click)(CGPoint point);
@property (nonatomic, copy) void(^ _Nullable click)(CGPoint downPoint, CGPoint upPoint);

/**
 设置url图片

 @param url 图片url
 */
- (void)mobi_setImageWithURL:(nonnull NSURL *)url;

/**
 设置url图片

 @param url 图片url
 @param placeholder 占位图
 */
- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder;

/**
 设置url图片

 @param url 图片url
 @param placeholder 占位图
 @param options MobiLaunchAdImageOptions
 */
- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(MobiLaunchAdImageOptions)options;

/**
 设置url图片

 @param url 图片url
 @param placeholder 占位图
 @param completedBlock MobiExternalCompletionBlock
 */
- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable MobiExternalCompletionBlock)completedBlock;

/**
 设置url图片

 @param url 图片url
 @param completedBlock MobiExternalCompletionBlock
 */
- (void)mobi_setImageWithURL:(nonnull NSURL *)url completed:(nullable MobiExternalCompletionBlock)completedBlock;


/**
 设置url图片

 @param url 图片url
 @param placeholder 占位图
 @param options MobiLaunchAdImageOptions
 @param completedBlock MobiExternalCompletionBlock
 */
- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(MobiLaunchAdImageOptions)options completed:(nullable MobiExternalCompletionBlock)completedBlock;

/**
 设置url图片

 @param url 图片url
 @param placeholder 占位图
 @param GIFImageCycleOnce gif是否只循环播放一次
 @param options MobiLaunchAdImageOptions
 @param cycleOnceFinishBlock gif播放完回调(GIFImageCycleOnce = YES 有效)
 @param completedBlock MobiExternalCompletionBlock
 */
- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder GIFImageCycleOnce:(BOOL)GIFImageCycleOnce options:(MobiLaunchAdImageOptions)options GIFImageCycleOnceFinish:(void(^_Nullable)(void))cycleOnceFinishBlock completed:(nullable MobiExternalCompletionBlock)completedBlock ;

@end

