//
//  MobiLaunchAdDownloader.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//MARK: MobiLaunchAdDownload

typedef void(^MobiLaunchAdDownloadProgressBlock)(unsigned long long total, unsigned long long current);

typedef void(^MobiLaunchAdDownloadImageCompletedBlock)(UIImage *_Nullable image, NSData * _Nullable data, NSError * _Nullable error);

typedef void(^MobiLaunchAdDownloadVideoCompletedBlock)(NSURL * _Nullable location, NSError * _Nullable error);

typedef void(^MobiLaunchAdBatchDownLoadAndCacheCompletedBlock) (NSArray * _Nonnull completedArray);

@protocol MobiLaunchAdDownloadDelegate <NSObject>

- (void)downloadFinishWithURL:(nonnull NSURL *)url;

@end

@interface MobiLaunchAdDownload : NSObject
@property (assign, nonatomic ,nonnull)id<MobiLaunchAdDownloadDelegate> delegate;
@end

@interface MobiLaunchAdImageDownload : MobiLaunchAdDownload

@end

//@interface XHLaunchAdVideoDownload : MobiLaunchAdDownload
//
//@end

//MARK: MobiLaunchAdDownloader

@interface MobiLaunchAdDownloader : NSObject

+(nonnull instancetype )sharedDownloader;

- (void)downloadImageWithURL:(nonnull NSURL *)url progress:(nullable MobiLaunchAdDownloadProgressBlock)progressBlock completed:(nullable MobiLaunchAdDownloadImageCompletedBlock)completedBlock;

- (void)downLoadImageAndCacheWithURLArray:(nonnull NSArray <NSURL *> * )urlArray;
- (void)downLoadImageAndCacheWithURLArray:(nonnull NSArray <NSURL *> * )urlArray completed:(nullable MobiLaunchAdBatchDownLoadAndCacheCompletedBlock)completedBlock;


@end

NS_ASSUME_NONNULL_END
