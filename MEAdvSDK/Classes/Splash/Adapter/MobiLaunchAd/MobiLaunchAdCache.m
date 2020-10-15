//
//  MobiLaunchAdCache.m
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "MobiLaunchAdCache.h"
#import <CommonCrypto/CommonDigest.h>
#import "MobiLaunchAdConst.h"

@implementation MobiLaunchAdCache

#pragma mark - 图片

+(UIImage *)getCacheImageWithURL:(NSURL *)url{
    if(url==nil) return nil;
    NSData *data = [NSData dataWithContentsOfFile:[self imagePathWithURL:url]];
    return [UIImage imageWithData:data];
}

+(NSData *)getCacheImageDataWithURL:(NSURL *)url{
    if(url==nil) return nil;
    return [NSData dataWithContentsOfFile:[self imagePathWithURL:url]];
}

+(BOOL)saveImageData:(NSData *)data imageURL:(NSURL *)url{
    NSString *path = [NSString stringWithFormat:@"%@/%@",[self mobiLaunchAdCachePath],[self keyWithURL:url]];
    if (data) {
        BOOL result = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
        if (!result) MobiLaunchAdLog(@"cache file error for URL: %@", url);
        return result;
    }
    return NO;
}

+(void)async_saveImageData:(NSData *)data imageURL:(NSURL *)url completed:(nullable SaveCompletionBlock)completedBlock{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL result = [self saveImageData:data imageURL:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completedBlock) completedBlock(result , url);
        });
    });
}

+ (NSString *)mobiLaunchAdCachePath{
    NSString *path =[NSHomeDirectory() stringByAppendingPathComponent:@"Library/MobiLaunchAdCache"];
    [self checkDirectory:path];
    return path;
}

+(NSString *)imagePathWithURL:(NSURL *)url{
    if(url==nil) return nil;
    return [[self mobiLaunchAdCachePath] stringByAppendingPathComponent:[self keyWithURL:url]];
}


+(BOOL)checkImageInCacheWithURL:(NSURL *)url{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self imagePathWithURL:url]];
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

#pragma mark - 图片url缓存
+(void)async_saveImageUrl:(NSString *)url{
    if(url==nil) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSUserDefaults standardUserDefaults] setObject:url forKey:MobiCacheImageUrlStringKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

+(NSString *)getCacheImageUrl{
   return [[NSUserDefaults standardUserDefaults] objectForKey:MobiCacheImageUrlStringKey];
}

#pragma mark - 其他
+(void)clearDiskCache{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [self mobiLaunchAdCachePath];
        [fileManager removeItemAtPath:path error:nil];
        [self checkDirectory:[self mobiLaunchAdCachePath]];
    });
}

+(void)clearDiskCacheWithImageUrlArray:(NSArray<NSURL *> *)imageUrlArray{
    if(imageUrlArray.count==0) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [imageUrlArray enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([self checkImageInCacheWithURL:obj]){
                [[NSFileManager defaultManager] removeItemAtPath:[self imagePathWithURL:obj] error:nil];
            }
        }];
    });
}

+(void)clearDiskCacheExceptImageUrlArray:(NSArray<NSURL *> *)exceptImageUrlArray{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *allFilePaths = [self allFilePathWithDirectoryPath:[self mobiLaunchAdCachePath]];
        NSArray *exceptImagePaths = [self filePathsWithFileUrlArray:exceptImageUrlArray videoType:NO];
        [allFilePaths enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(![exceptImagePaths containsObject:obj] && !MobiISVideoTypeWithPath(obj)){
                [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
            }
        }];
        MobiLaunchAdLog(@"allFilePath = %@",allFilePaths);
    });
}

+(float)diskCacheSize{
    NSString *directoryPath = [self mobiLaunchAdCachePath];
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
//            path = [self videoPathWithURL:obj];
        }else{
            path = [self imagePathWithURL:obj];
        }
        [filePaths addObject:path];
    }];
    return filePaths;
}

+(NSArray *)allFilePathWithDirectoryPath:(NSString*)directoryPath{
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
    MobiLaunchAdLog(@"MobiLaunchAdCachePath = %@",path);
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

+(NSString *)keyWithURL:(NSURL *)url{
    return [self md5String:url.absoluteString];
}


@end
