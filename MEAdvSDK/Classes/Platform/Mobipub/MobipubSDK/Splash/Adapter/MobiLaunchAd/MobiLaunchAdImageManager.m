//
//  MobiLaunchAdImageManager.m
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/30.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "MobiLaunchAdImageManager.h"
#import "MobiLaunchAdCache.h"

@interface MobiLaunchAdImageManager ()

@property(nonatomic,strong) MobiLaunchAdDownloader *downloader;

@end

@implementation MobiLaunchAdImageManager

+(nonnull instancetype )sharedManager{
    static MobiLaunchAdImageManager *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[MobiLaunchAdImageManager alloc] init];
        
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _downloader = [MobiLaunchAdDownloader sharedDownloader];
    }
    return self;
}

- (void)loadImageWithURL:(nullable NSURL *)url options:(MobiLaunchAdImageOptions)options progress:(nullable MobiLaunchAdDownloadProgressBlock)progressBlock completed:(nullable MobiExternalCompletionBlock)completedBlock{
    if(!options) options = MobiLaunchAdImageDefault;
    if(options & MobiLaunchAdImageOnlyLoad){
        [_downloader downloadImageWithURL:url progress:progressBlock completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error) {
            if(completedBlock) completedBlock(image,data,error,url);
        }];
    }else if (options & MobiLaunchAdImageRefreshCached){
        NSData *imageData = [MobiLaunchAdCache getCacheImageDataWithURL:url];
        UIImage *image =  [UIImage imageWithData:imageData];
        if(image && completedBlock) completedBlock(image,imageData,nil,url);
        [_downloader downloadImageWithURL:url progress:progressBlock completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error) {
            if(completedBlock) completedBlock(image,data,error,url);
            [MobiLaunchAdCache async_saveImageData:data imageURL:url completed:nil];
        }];
    }else if (options & MobiLaunchAdImageCacheInBackground){
        NSData *imageData = [MobiLaunchAdCache getCacheImageDataWithURL:url];
        UIImage *image =  [UIImage imageWithData:imageData];
        if(image && completedBlock){
            completedBlock(image,imageData,nil,url);
        }else{
            [_downloader downloadImageWithURL:url progress:progressBlock completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error) {
                [MobiLaunchAdCache async_saveImageData:data imageURL:url completed:nil];
            }];
        }
    }else{//default
        NSData *imageData = [MobiLaunchAdCache getCacheImageDataWithURL:url];
        UIImage *image =  [UIImage imageWithData:imageData];
        if(image && completedBlock){
            completedBlock(image,imageData,nil,url);
        }else{
            [_downloader downloadImageWithURL:url progress:progressBlock completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error) {
                if(completedBlock) completedBlock(image,data,error,url);
                [MobiLaunchAdCache async_saveImageData:data imageURL:url completed:nil];
            }];
        }
    }
}

@end
