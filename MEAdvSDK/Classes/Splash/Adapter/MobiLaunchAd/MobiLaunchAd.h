//
//  MobiLaunchAd.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobiLaunchAdConst.h"
#import "MobiLaunchImageView.h"
#import "MobiLaunchAdConfiguration.h"
#import "MPAdDestinationDisplayAgent.h"// 展示点击广告后的效果的代理类

NS_ASSUME_NONNULL_BEGIN
@class MobiLaunchAd;
@class MobiLaunchAdReportModel;
@protocol MobiLaunchAdDelegate <NSObject>
@optional

/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForLaunchAd:(MobiLaunchAd *)launchAd withError:(NSError *)error;

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForLaunchAd:(MobiLaunchAd *)launchAd reportModel:(MobiLaunchAdReportModel *)model;

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForLaunchAd:(MobiLaunchAd *)launchAd;

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdCustomSkipView:(UIView * _Nullable)customSkipView LifeTime:(NSUInteger)time;


///**
// *  video本地读取/或下载完成回调
// *
// *  @param launchAd MobiLaunchAd
// *  @param pathURL  本地保存路径
// */
//-(void)mobiLaunchAd:(MobiLaunchAd *)launchAd videoDownLoadFinish:(NSURL *)pathURL;
//
///**
// 视频下载进度回调
//
// @param launchAd MobiLaunchAd
// @param progress 下载进度
// @param total    总大小
// @param current  当前已下载大小
// */
//-(void)mobiLaunchAd:(MobiLaunchAd *)launchAd videoDownLoadProgress:(float)progress total:(unsigned long long)total current:(unsigned long long)current;


@end

@interface MobiLaunchAd : NSObject<MPAdDestinationDisplayAgentDelegate>

/**
 * 代理
*/
@property(nonatomic, weak) id<MobiLaunchAdDelegate> delegate;

/**
 设置你工程的启动页使用的是LaunchImage还是LaunchScreen(default:LaunchScreen)
 注意:请在设置等待数据及配置广告数据前调用此方法
 @param sourceType sourceType
 */
+ (void)setLaunchSourceType:(MobiSourceType)sourceType;

/**
 *  设置等待数据源时间(建议值:2)
 *  未设置此方法，则没有等待时间，适用于加载本地图片或gif
 *
 *  @param waitDataDuration waitDataDuration
 */
//+ (void)setWaitDataDuration:(NSInteger )waitDataDuration;

/**
 *  图片开屏广告数据配置
 *
 *  @param imageAdconfiguration 数据配置
 *
 *  @return MobiLaunchAd
 */
+ (MobiLaunchAd *)imageAdWithImageAdConfiguration:(MobiLaunchImageAdConfiguration *)imageAdconfiguration;

/**
 *  图片开屏广告数据配置
 *
 *  @param imageAdconfiguration 数据配置
 *  @param delegate             delegate
 *
 *  @return MobiLaunchAd
 */
+ (MobiLaunchAd *)imageAdWithImageAdConfiguration:(MobiLaunchImageAdConfiguration *)imageAdconfiguration delegate:(nullable id)delegate;

//MARK: 批量下载并缓存
/**
 *  批量下载并缓存image(异步) - 已缓存的image不会再次下载缓存
 *
 *  @param urlArray image URL Array
 */
+ (void)downLoadImageAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray;

/**
 批量下载并缓存image,并回调结果(异步)- 已缓存的image不会再次下载缓存

 @param urlArray image URL Array
 @param completedBlock 回调结果为一个字典数组,url:图片的url字符串,result:0表示该图片下载缓存失败,1表示该图片下载并缓存完成或本地缓存中已有该图片
 */
+ (void)downLoadImageAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray completed:(nullable MobiLaunchAdBatchDownLoadAndCacheCompletedBlock)completedBlock;

//MARK: Action

/**
 手动移除广告

 @param animated 是否需要动画
 */
+ (void)removeAndAnimated:(BOOL)animated;

//MARK: 是否已缓存
/**
 *  是否已缓存在该图片
 *
 *  @param url image url
 *
 *  @return BOOL
 */
+ (BOOL)checkImageInCacheWithURL:(NSURL *)url;

//MARK: 获取缓存url
/**
 从缓存中获取上一次的ImageURLString(XHLaunchAd 会默认缓存imageURLString)
 
 @return imageUrlString
 */
+ (NSString *)cacheImageURLString;


//MARK: 缓存/清理相关
/**
 *  清除XHLaunchAd本地所有缓存(异步)
 */
+ (void)clearDiskCache;

/**
 清除指定Url的图片本地缓存(异步)

 @param imageUrlArray 需要清除缓存的图片Url数组
 */
+ (void)clearDiskCacheWithImageUrlArray:(NSArray<NSURL *> *)imageUrlArray;

/**
 清除指定Url除外的图片本地缓存(异步)
 
 @param exceptImageUrlArray 此url数组的图片缓存将被保留
 */
+ (void)clearDiskCacheExceptImageUrlArray:(NSArray<NSURL *> *)exceptImageUrlArray;

/**
 *  获取XHLaunch本地缓存大小(M)
 */
+ (float)diskCacheSize;

/**
 *  缓存路径
 */
+ (NSString *)mobiLaunchAdCachePath;

@end

/// 上报的数据模型
@interface MobiLaunchAdReportModel : NSObject

@property(nonatomic,assign) CGPoint clickDownPoint;

@property(nonatomic,assign) CGPoint clickUpPoint;

@end

NS_ASSUME_NONNULL_END
