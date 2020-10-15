//
//  XHLaunchAdDownloaderManager.m
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 16/12/1.
//  Copyright © 2016年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd

#import "MobiVideoAdDownloader.h"
#import "MobiVideoAdCache.h"
#import "MobiLaunchAdConst.h"

#if __has_include(<FLAnimatedImage/FLAnimatedImage.h>)
    #import <FLAnimatedImage/FLAnimatedImage.h>
#else
    #import "FLAnimatedImage.h"
#endif

#pragma mark - XHLaunchAdDownload

@interface MobiVideoAdDownload()

@property (strong, nonatomic) NSURLSession *session;
@property(strong,nonatomic)NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) unsigned long long totalLength;
@property (nonatomic, assign) unsigned long long currentLength;
@property (nonatomic, copy) MobiVideoAdDownloadProgressBlock progressBlock;
@property (strong, nonatomic) NSURL *url;

@end
@implementation MobiVideoAdDownload

@end

#pragma makr - XHLaunchAdVideoDownload
@interface MobiVideoAdVideoDownload()<NSURLSessionDownloadDelegate,NSURLSessionTaskDelegate>

@property (nonatomic, copy ) MobiVideoAdDownloadVideoCompletedBlock completedBlock;
@end

@implementation MobiVideoAdVideoDownload

-(nonnull instancetype)initWithURL:(nonnull NSURL *)url delegateQueue:(nonnull NSOperationQueue *)queue progress:(nullable MobiVideoAdDownloadProgressBlock)progressBlock completed:(nullable MobiVideoAdDownloadVideoCompletedBlock)completedBlock{
    self = [super init];
    if (self) {
        self.url = url;
        self.progressBlock = progressBlock;
        _completedBlock = completedBlock;
        NSURLSessionConfiguration * sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.timeoutIntervalForRequest = 3.0;
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:queue];
        self.downloadTask =  [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:url]];
        [self.downloadTask resume];
    }
    return self;
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSError *error=nil;
    NSURL *toURL = [NSURL fileURLWithPath:[MobiVideoAdCache videoPathWithURL:self.url]];

    [[NSFileManager defaultManager] copyItemAtURL:location toURL:toURL error:&error];//复制到缓存目录

    if(error)  MobiLaunchAdLog(@"error = %@",error);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completedBlock) {
            if(!error){
                self.completedBlock(toURL,nil);
            }else{
                self.completedBlock(nil,error);
            }
            // 防止重复调用
            self.completedBlock = nil;
        }
        //下载完成回调
        if ([self.delegate respondsToSelector:@selector(downloadFinishWithURL:)]) {
            [self.delegate downloadFinishWithURL:self.url];
        }
    });
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.currentLength = totalBytesWritten;
    self.totalLength = totalBytesExpectedToWrite;
    if (self.progressBlock) {
        self.progressBlock(self.totalLength, self.currentLength);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error){
        MobiLaunchAdLog(@"error = %@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completedBlock) {
                self.completedBlock(nil, error);
            }
            self.completedBlock = nil;
        });
    }
}
@end

#pragma mark - XHLaunchAdDownloader
@interface MobiVideoAdDownloader()<MobiVideoAdDownloadDelegate>
@property (strong, nonatomic, nonnull) NSOperationQueue *downloadImageQueue;
@property (strong, nonatomic, nonnull) NSOperationQueue *downloadVideoQueue;
@property (strong, nonatomic) NSMutableDictionary *allDownloadDict;
@end

@implementation MobiVideoAdDownloader

+(nonnull instancetype )sharedDownloader{
    static MobiVideoAdDownloader *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[MobiVideoAdDownloader alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _downloadImageQueue = [NSOperationQueue new];
        _downloadImageQueue.maxConcurrentOperationCount = 6;
        _downloadImageQueue.name = @"com.it7090.XHLaunchAdDownloadImageQueue";
        _downloadVideoQueue = [NSOperationQueue new];
        _downloadVideoQueue.maxConcurrentOperationCount = 3;
        _downloadVideoQueue.name = @"com.it7090.XHLaunchAdDownloadVideoQueue";
        MobiLaunchAdLog(@"XHLaunchAdCachePath:%@",[MobiVideoAdCache xhLaunchAdCachePath]);
    }
    return self;
}



- (void)downloadVideoWithURL:(nonnull NSURL *)url progress:(nullable MobiVideoAdDownloadProgressBlock)progressBlock completed:(nullable MobiVideoAdDownloadVideoCompletedBlock)completedBlock{
    NSString *key = [self keyWithURL:url];
    if(self.allDownloadDict[key]) return;
    MobiVideoAdVideoDownload * download = [[MobiVideoAdVideoDownload alloc] initWithURL:url delegateQueue:_downloadVideoQueue progress:progressBlock completed:completedBlock];
    download.delegate = self;
    [self.allDownloadDict setObject:download forKey:key];
}

- (void)downloadVideoAndCacheWithURL:(nonnull NSURL *)url completed:(void(^)(BOOL result))completedBlock{
    if(url == nil){
        if(completedBlock) completedBlock(NO);
        return;
    }
    [self downloadVideoWithURL:url progress:nil completed:^(NSURL * _Nullable location, NSError * _Nullable error) {
        if(error){
            if(completedBlock) completedBlock(NO);
        }else{
            if(completedBlock) completedBlock(YES);
        }
    }];
}

- (void)downLoadVideoAndCacheWithURLArray:(nonnull NSArray <NSURL *> * )urlArray{
    [self downLoadVideoAndCacheWithURLArray:urlArray completed:nil];
}

- (void)downLoadVideoAndCacheWithURLArray:(nonnull NSArray <NSURL *> * )urlArray completed:(nullable MobiVideoAdBatchDownLoadAndCacheCompletedBlock)completedBlock{
    if(urlArray.count==0) return;
    __block NSMutableArray * resultArray = [[NSMutableArray alloc] init];
    dispatch_group_t downLoadGroup = dispatch_group_create();
    [urlArray enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
        if(![MobiVideoAdCache checkVideoInCacheWithURL:url]){
             dispatch_group_enter(downLoadGroup);
            [self downloadVideoAndCacheWithURL:url completed:^(BOOL result) {
               dispatch_group_leave(downLoadGroup);
                [resultArray addObject:@{@"url":url.absoluteString,@"result":@(result)}];
            }];
        }else{
           [resultArray addObject:@{@"url":url.absoluteString,@"result":@(YES)}];
        }
    }];
    dispatch_group_notify(downLoadGroup, dispatch_get_main_queue(), ^{
        if(completedBlock) completedBlock(resultArray);
    });
}

- (NSMutableDictionary *)allDownloadDict {
    if (!_allDownloadDict) {
        _allDownloadDict = [[NSMutableDictionary alloc] init];
    }
    return _allDownloadDict;
}

- (void)downloadFinishWithURL:(NSURL *)url{
    [self.allDownloadDict removeObjectForKey:[self keyWithURL:url]];
}

-(NSString *)keyWithURL:(NSURL *)url{
    return [MobiVideoAdCache md5String:url.absoluteString];
}

@end

