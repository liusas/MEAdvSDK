//
//  XHLaunchAdCache.m
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 16/6/13.
//  Copyright © 2016年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd

#import "MobiVideoAdCache.h"
#import <CommonCrypto/CommonDigest.h>
#import "MobiLaunchAdConst.h"

@implementation MobiVideoAdCache

+(BOOL)saveVideoAtLocation:(NSURL *)location URL:(NSURL *)url{
    NSString *savePath = [[self xhLaunchAdCachePath] stringByAppendingPathComponent:[self videoNameWithURL:url]];
    NSURL *savePathUrl = [NSURL fileURLWithPath:savePath];
    BOOL result =[[NSFileManager defaultManager] moveItemAtURL:location toURL:savePathUrl error:nil];
    if(!result) MobiLaunchAdLog(@"cache file error for URL: %@", url);
    return  result;
}

+(void)async_saveVideoAtLocation:(NSURL *)location URL:(NSURL *)url completed:(nullable SaveCompletionBlock)completedBlock{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       BOOL result = [self saveVideoAtLocation:location URL:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completedBlock) completedBlock(result , url);
        });
    });
}

+(nullable NSURL *)getCacheVideoWithURL:(NSURL *)url{
    NSString *savePath = [[self xhLaunchAdCachePath] stringByAppendingPathComponent:[self videoNameWithURL:url]];
    //如果存在
    if([[NSFileManager defaultManager] fileExistsAtPath:savePath]){
        return [NSURL fileURLWithPath:savePath];
    }
    return nil;
}

+ (NSString *)xhLaunchAdCachePath{
    NSString *path =[NSHomeDirectory() stringByAppendingPathComponent:@"Library/MobiLaunchAdCache"];
    [self checkDirectory:path];
    return path;
}

+(NSString *)videoPathWithURL:(NSURL *)url{
    if(url==nil) return nil;
    return [[self xhLaunchAdCachePath] stringByAppendingPathComponent:[self videoNameWithURL:url]];
}

+(NSString *)videoPathWithFileName:(NSString *)videoFileName{
    if(videoFileName.length==0) return nil;
    return [[self xhLaunchAdCachePath] stringByAppendingPathComponent:[self videoNameWithURL:[NSURL URLWithString:videoFileName]]];
}

+(BOOL)checkVideoInCacheWithURL:(NSURL *)url{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self videoPathWithURL:url]];
}

+(BOOL)checkVideoInCacheWithFileName:(NSString *)videoFileName{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self videoPathWithFileName:videoFileName]];
}

+(void)checkDirectory:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    } else {
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}

#pragma mark - url缓存

+(void)async_saveVideoUrl:(NSString *)url{
    if(url==nil) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSUserDefaults standardUserDefaults] setObject:url forKey:MobiCacheVideoUrlStringKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

+(NSString *)getCacheVideoUrl{
  return [[NSUserDefaults standardUserDefaults] objectForKey:MobiCacheVideoUrlStringKey];
}

#pragma mark - 其他
+(void)clearDiskCache{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [self xhLaunchAdCachePath];
        [fileManager removeItemAtPath:path error:nil];
        [self checkDirectory:[self xhLaunchAdCachePath]];
    });
}

+(void)clearDiskCacheWithVideoUrlArray:(NSArray<NSURL *> *)videoUrlArray{
    if(videoUrlArray.count==0) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [videoUrlArray enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([self checkVideoInCacheWithURL:obj]){
                [[NSFileManager defaultManager] removeItemAtPath:[self videoPathWithURL:obj] error:nil];
            }
        }];
    });
}

+(void)clearDiskCacheExceptVideoUrlArray:(NSArray<NSURL *> *)exceptVideoUrlArray{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *allFilePaths = [self allFilePathWithDirectoryPath:[self xhLaunchAdCachePath]];
        NSArray *exceptVideoPaths = [self filePathsWithFileUrlArray:exceptVideoUrlArray videoType:YES];
        [allFilePaths enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(![exceptVideoPaths containsObject:obj] && MobiISVideoTypeWithPath(obj)){
                [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
            }
        }];
        MobiLaunchAdLog(@"allFilePath = %@",allFilePaths);
    });
}

+(float)diskCacheSize{
    NSString *directoryPath = [self xhLaunchAdCachePath];
    BOOL isDir = NO;
    unsigned long long total = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    return total/(1024.0*1024.0);
}

+(NSArray *)filePathsWithFileUrlArray:(NSArray <NSURL *> *)fileUrlArray videoType:(BOOL)videoType{
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    [fileUrlArray enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path;
        if(videoType){
            path = [self videoPathWithURL:obj];
        }else{
            //path = [self imagePathWithURL:obj];
        }
        [filePaths addObject:path];
    }];
    return filePaths;
}

+(NSArray*)allFilePathWithDirectoryPath:(NSString*)directoryPath{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* tempArray = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
    for (NSString* fileName in tempArray) {
        BOOL flag = YES;
        NSString* fullPath = [directoryPath stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&flag]) {
            if (!flag) {
                [array addObject:fullPath];
            }
        }
    }
    return array;
}

+ (void)createBaseDirectoryAtPath:(NSString *)path {
    __autoreleasing NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        MobiLaunchAdLog(@"create cache directory failed, error = %@", error);
    } else {
        [self addDoNotBackupAttribute:path];
    }
    MobiLaunchAdLog(@"XHLaunchAdCachePath = %@",path);
}

+ (void)addDoNotBackupAttribute:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (error) {
        MobiLaunchAdLog(@"error to set do not backup attribute, error = %@", error);
    }
}

+(NSString *)md5String:(NSString *)string{
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    return outputString;
}

+(NSString *)videoNameWithURL:(NSURL *)url{
     return [[self md5String:url.absoluteString] stringByAppendingString:@".mp4"];
}

+(NSString *)keyWithURL:(NSURL *)url{
    return [self md5String:url.absoluteString];
}

@end