//
//  MobiLaunchAdDownloader.m
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "MobiLaunchAdDownloader.h"
#import "MobiLaunchAdCache.h"
#import "MobiLaunchAdConst.h"

#if __has_include(<FLAnimatedImage/FLAnimatedImage.h>)
    #import <FLAnimatedImage/FLAnimatedImage.h>
#else
    #import "FLAnimatedImage.h"
#endif

//MARK: MobiLaunchAdDownload

@interface MobiLaunchAdDownload()

@property (strong, nonatomic) NSURLSession *session;
@property(strong,nonatomic)NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) unsigned long long totalLength;
@property (nonatomic, assign) unsigned long long currentLength;
@property (nonatomic, copy) MobiLaunchAdDownloadProgressBlock progressBlock;
@property (strong, nonatomic) NSURL *url;

@end

@implementation MobiLaunchAdDownload

@end

//MARK: MobiLaunchAdImageDownload

@interface MobiLaunchAdImageDownload()<NSURLSessionDownloadDelegate,NSURLSessionTaskDelegate>

@property (nonatomic, copy ) MobiLaunchAdDownloadImageCompletedBlock completedBlock;

@end
@implementation MobiLaunchAdImageDownload

-(nonnull instancetype)initWithURL:(nonnull NSURL *)url delegateQueue:(nonnull NSOperationQueue *)queue progress:(nullable MobiLaunchAdDownloadProgressBlock)progressBlock completed:(nullable MobiLaunchAdDownloadImageCompletedBlock)completedBlock{
    self = [super init];
    if (self) {
        self.url = url;
        self.progressBlock = progressBlock;
        self.completedBlock = completedBlock;
        NSURLSessionConfiguration * sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.timeoutIntervalForRequest = 15.0;
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:queue];
        self.downloadTask =  [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:url]];
        [self.downloadTask resume];
    }
    return self;
}

//MARK: NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    UIImage *image = [UIImage imageWithData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completedBlock) {
            self.completedBlock(image,data, nil);
            // 防止重复调用
            self.completedBlock = nil;
        }
        //下载完成回调
        if ([self.delegate respondsToSelector:@selector(downloadFinishWithURL:)]) {
            [self.delegate downloadFinishWithURL:self.url];
        }
    });
    //销毁
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
                self.completedBlock(nil,nil, error);
            }
            self.completedBlock = nil;
        });
    }
}

//处理HTTPS请求的
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = protectionSpace.serverTrust;
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end


//MARK: MobiLaunchAdDownloader

@interface MobiLaunchAdDownloader()<MobiLaunchAdDownloadDelegate>
@property (strong, nonatomic, nonnull) NSOperationQueue *downloadImageQueue;
//@property (strong, nonatomic, nonnull) NSOperationQueue *downloadVideoQueue;
@property (strong, nonatomic) NSMutableDictionary *allDownloadDict;
@end

@implementation MobiLaunchAdDownloader

+(nonnull instancetype )sharedDownloader{
    static MobiLaunchAdDownloader *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[MobiLaunchAdDownloader alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _downloadImageQueue = [NSOperationQueue new];
        _downloadImageQueue.maxConcurrentOperationCount = 6;
        _downloadImageQueue.name = @"com.mobiexchanger.MobiLaunchAdDownloadImageQueue";
//        _downloadVideoQueue = [NSOperationQueue new];
//        _downloadVideoQueue.maxConcurrentOperationCount = 3;
//        _downloadVideoQueue.name = @"com.it7090.XHLaunchAdDownloadVideoQueue";
        MobiLaunchAdLog(@"MobiLaunchAdCachePath:%@",[MobiLaunchAdCache mobiLaunchAdCachePath]);
    }
    return self;
}

//MARK: 下载图片
- (void)downloadImageWithURL:(nonnull NSURL *)url progress:(nullable MobiLaunchAdDownloadProgressBlock)progressBlock completed:(nullable MobiLaunchAdDownloadImageCompletedBlock)completedBlock{
    NSString *key = [self keyWithURL:url];
    if(self.allDownloadDict[key]) return;
    MobiLaunchAdImageDownload * download = [[MobiLaunchAdImageDownload alloc] initWithURL:url delegateQueue:_downloadImageQueue progress:progressBlock completed:completedBlock];
    download.delegate = self;
    [self.allDownloadDict setObject:download forKey:key];
}

//MARK: 下载图片数组
-(void)downLoadImageAndCacheWithURLArray:(NSArray<NSURL *> *)urlArray{
    [self downLoadImageAndCacheWithURLArray:urlArray completed:nil];
}

- (void)downLoadImageAndCacheWithURLArray:(nonnull NSArray <NSURL *> * )urlArray completed:(nullable MobiLaunchAdBatchDownLoadAndCacheCompletedBlock)completedBlock{
    if(urlArray.count==0) return;
    __block NSMutableArray * resultArray = [[NSMutableArray alloc] init];
    dispatch_group_t downLoadGroup = dispatch_group_create();
    [urlArray enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
        if(![MobiLaunchAdCache checkImageInCacheWithURL:url]){
            dispatch_group_enter(downLoadGroup);
            [self downloadImageAndCacheWithURL:url completed:^(BOOL result) {
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

//下载并缓存图片，图片数组下载时使用
- (void)downloadImageAndCacheWithURL:(nonnull NSURL *)url completed:(void(^)(BOOL result))completedBlock{
    if(url == nil){
         if(completedBlock) completedBlock(NO);
         return;
    }
    [self downloadImageWithURL:url progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error) {
        if(error){
            if(completedBlock) completedBlock(NO);
        }else{
            [MobiLaunchAdCache async_saveImageData:data imageURL:url completed:^(BOOL result, NSURL * _Nonnull URL) {
                if(completedBlock) completedBlock(result);
            }];
        }
    }];
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
    return [MobiLaunchAdCache md5String:url.absoluteString];
}

@end
