//
//  MobiLaunchAdCache.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SaveCompletionBlock)(BOOL result , NSURL * URL);

@interface MobiLaunchAdCache : NSObject

//MARK: 图片
/**
 *  获取缓存图片
 *
 *  @param url 图片url
 *
 *  @return 图片
 */
+(UIImage *)getCacheImageWithURL:(NSURL *)url;

/**
 获取缓存图片

 @param url 图片url
 @return imageData
 */
+(NSData *)getCacheImageDataWithURL:(NSURL *)url;

/**
 缓存图片

 @param data imageData
 @param url 图片url
 @return 缓存结果
 */
+(BOOL)saveImageData:(NSData *)data imageURL:(NSURL *)url;

/**
 缓存图片 - 异步

 @param data imageData
 @param url 图片url
 @param completedBlock 结果回调
 */
+(void)async_saveImageData:(NSData *)data imageURL:(NSURL *)url completed:(nullable SaveCompletionBlock)completedBlock;

/**
 *  检查是否已缓存在该图片
 *
 *  @param url image url
 *
 *  @return BOOL
 */

+(BOOL)checkImageInCacheWithURL:(NSURL *)url;

//MARK: 图片url缓存
/**
 存储图片url - 异步
 
 @param url 图片url
 */
+(void)async_saveImageUrl:(NSString *)url;

/**
 获取最后一次缓存的图片url
 
 @return url string
 */
+(NSString *)getCacheImageUrl;


//MARK: 其他
/**
 *  缓存路径
 */
+ (NSString *)mobiLaunchAdCachePath;

/**
 *  清除MobiLaunchAd本地所有缓存(异步)
 */
+(void)clearDiskCache;

/**
 清除指定Url的图片本地缓存(异步)
 
 @param imageUrlArray 图片Url数组
 */
+(void)clearDiskCacheWithImageUrlArray:(NSArray<NSURL *> *)imageUrlArray;

/**
 清除指定Url除外的图片本地缓存(异步)

 @param exceptImageUrlArray 不需要清除缓存的图片Url数组,此url数组图片缓存将被保留
 */
+(void)clearDiskCacheExceptImageUrlArray:(NSArray<NSURL *> *)exceptImageUrlArray;

/**
 *  获取XHLaunch本地缓存大小(M)
 */
+(float)diskCacheSize;

#pragma mark - other

+(NSString *)md5String:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
