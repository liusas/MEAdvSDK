//
//  XHLaunchAdDownloaderManager.h
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 16/12/1.
//  Copyright © 2016年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - XHLaunchAdDownload

typedef void(^MobiVideoAdDownloadProgressBlock)(unsigned long long total, unsigned long long current);

typedef void(^MobiVideoAdDownloadImageCompletedBlock)(UIImage *_Nullable image, NSData * _Nullable data, NSError * _Nullable error);

typedef void(^MobiVideoAdDownloadVideoCompletedBlock)(NSURL * _Nullable location, NSError * _Nullable error);

typedef void(^MobiVideoAdBatchDownLoadAndCacheCompletedBlock) (NSArray * _Nonnull completedArray);

@protocol MobiVideoAdDownloadDelegate <NSObject>

- (void)downloadFinishWithURL:(nonnull NSURL *)url;

@end

@interface MobiVideoAdDownload : NSObject
@property (assign, nonatomic ,nonnull)id<MobiVideoAdDownloadDelegate> delegate;
@end

@interface MobiVideoAdVideoDownload : MobiVideoAdDownload

@end

#pragma mark - MobiVideoAdDownloader
@interface MobiVideoAdDownloader : NSObject

+(nonnull instancetype )sharedDownloader;

- (void)downloadVideoWithURL:(nonnull NSURL *)url progress:(nullable MobiVideoAdDownloadProgressBlock)progressBlock completed:(nullable MobiVideoAdDownloadVideoCompletedBlock)completedBlock;

- (void)downLoadVideoAndCacheWithURLArray:(nonnull NSArray <NSURL *> * )urlArray;
- (void)downLoadVideoAndCacheWithURLArray:(nonnull NSArray <NSURL *> * )urlArray completed:(nullable MobiVideoAdBatchDownLoadAndCacheCompletedBlock)completedBlock;

@end

