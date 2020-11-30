//
//  MobiLaunchAdImageManager.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/30.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MobiLaunchAdDownloader.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, MobiLaunchAdImageOptions) {
    /** 有缓存,读取缓存,不重新下载,没缓存先下载,并缓存 */
    MobiLaunchAdImageDefault = 1 << 0,
    /** 只下载,不缓存 */
    MobiLaunchAdImageOnlyLoad = 1 << 1,
    /** 先读缓存,再下载刷新图片和缓存 */
    MobiLaunchAdImageRefreshCached = 1 << 2 ,
    /** 后台缓存本次不显示,缓存OK后下次再显示(建议使用这种方式)*/
    MobiLaunchAdImageCacheInBackground = 1 << 3
};

typedef void(^MobiExternalCompletionBlock)(UIImage * _Nullable image,NSData * _Nullable imageData, NSError * _Nullable error, NSURL * _Nullable imageURL);

@interface MobiLaunchAdImageManager : NSObject

+(nonnull instancetype )sharedManager;

- (void)loadImageWithURL:(nullable NSURL *)url options:(MobiLaunchAdImageOptions)options progress:(nullable MobiLaunchAdDownloadProgressBlock)progressBlock completed:(nullable MobiExternalCompletionBlock)completedBlock;

@end

NS_ASSUME_NONNULL_END
