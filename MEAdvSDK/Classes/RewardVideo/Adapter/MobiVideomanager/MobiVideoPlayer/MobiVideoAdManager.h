//
//  MobiVideoAdManager.h
//  MobiPubSDK
//
//  Created by 李新丰 on 2020/8/7.
//

#import <Foundation/Foundation.h>
#import "MobiLaunchAdConfiguration.h"
#import "MobiVideoAdDownloader.h"
#import "MobiVideoAdCache.h"
#import "MobiAdVideoBaseClass.h"
#import "MPAdDestinationDisplayAgent.h"// 展示点击广告后的效果的代理类
#import "MobiXFVideoPlayController.h"

@class MobiVideoAdManager;
@protocol MobiVideoAdManagerDelegate <NSObject>

@optional
/// 视频广告 读取/下载/加载成功
- (void)rewardedVideo:(MobiVideoAdManager *)videoAd didLoadAdSuccess:(NSURL *)pathUrl;

/// 视频广告加载失败
- (void)rewardedVideoDidLoadAdFailed:(MobiVideoAdManager *)videoAd;

/// 视频加载成功,但是已无效,调用此方法
- (void)rewardedVideoDidLoadWithExpire:(MobiVideoAdManager *)videoAd;

/// 视频已经开始播放,但是没有播放完整(归为播放失败或者视频失效)
/// 当视图播放一个激励视频,但激励视频并没有播放成功时,调用此方法
/// 另一个调用此方法的原因是,要播放视频时,该视频失效了
- (void)rewardedVideoPlayFailedWithNoComplete:(MobiVideoAdManager *)videoAd;

/// 视频展现成功
- (void)rewardedVideoShowSuccess:(MobiVideoAdManager *)videoAd;

/// 视频展现失败
- (void)rewardedVideoShowFailed:(MobiVideoAdManager *)videoAd;

/// 视频广告关闭
- (void)rewardedVideoCloseClick:(MobiVideoAdManager *)videoAd;

/// 视频广告被点击
- (void)rewardedVideoDownloadClick:(MobiVideoAdManager *)videoAd;

/// 点击视频广告将要离开APP
- (void)rewardedVideoWillLeaveApp:(MobiVideoAdManager *)videoAd;

/// 视频播放进度回调
-(void)mobiVideoAd:(MobiVideoAdManager *)videoAd videoPlayProgress:(MobiVideoPlayProgressType)progress;
@end


@interface MobiVideoAdManager : NSObject

@property (nonatomic, weak) id<MobiVideoAdManagerDelegate> delegate;
@property (nonatomic, strong) UIViewController *controller;
@property (nonatomic, strong) MobiAdVideoBaseClass *videoDataBase;
@property (nonatomic, strong) id<MPAdDestinationDisplayAgent> destinationDisplayAgent;
+ (MobiVideoAdManager *)shareManager;
/**
 *  设置等待数据源时间(建议值:2)
 *
 *  @param waitDataDuration waitDataDuration
 */
+(void)setWaitDataDuration:(NSInteger )waitDataDuration;
/**
 *  视频广告数据配置
 *
 *  @param videoAdconfiguration 数据配置
 *
 *  @return XHLaunchAd
 */
+(MobiVideoAdManager *)videoAdWithVideoAdConfiguration:(MobiVideoAdConfiguration *)videoAdconfiguration;

/**
 *  视频广告数据配置
 *
 *  @param videoAdconfiguration 数据配置
 *  @param delegate             delegate
 *
 *  @return XHLaunchAd
 */
+(MobiVideoAdManager *)videoAdWithVideoAdConfiguration:(MobiVideoAdConfiguration *)videoAdconfiguration delegate:(nullable id)delegate;

#pragma mark -批量下载并缓存
/**
 *  批量下载并缓存image(异步) - 已缓存的image不会再次下载缓存
 *
 *  @param urlArray image URL Array
 */
+(void)downLoadImageAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray;

/**
 *  批量下载并缓存视频(异步) - 已缓存的视频不会再次下载缓存
 *
 *  @param urlArray 视频URL Array
 */
+(void)downLoadVideoAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray;

/**
 批量下载并缓存视频,并回调结果(异步) - 已缓存的视频不会再次下载缓存
 
 @param urlArray 视频URL Array
 @param completedBlock 回调结果为一个字典数组,url:视频的url字符串,result:0表示该视频下载缓存失败,1表示该视频下载并缓存完成或本地缓存中已有该视频
 */
+(void)downLoadVideoAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray completed:(nullable MobiVideoAdBatchDownLoadAndCacheCompletedBlock)completedBlock;

/// 去展示视频
/// @param controller 视频模态的controller
//+ (void)presentTopPlayVideoWithController:(UIViewController *)controller;

#pragma mark - Action

/**
 手动移除广告

 @param animated 是否需要动画
 */
+(void)removeAndAnimated:(BOOL)animated;

#pragma mark - 是否已缓存
/**
 *  是否已缓存该视频
 *
 *  @param url video url
 *
 *  @return BOOL
 */
+(BOOL)checkVideoInCacheWithURL:(NSURL *)url;

#pragma mark - 获取缓存url
/**
 从缓存中获取上一次的videoURLString(XHLaunchAd 会默认缓存VideoURLString)
 
 @return videoUrlString
 */
+(NSString *)cacheVideoURLString;

#pragma mark - 缓存/清理相关
/**
 *  清除XHLaunchAd本地所有缓存(异步)
 */
+(void)clearDiskCache;

/**
 清除指定Url的视频本地缓存(异步)

 @param videoUrlArray 需要清除缓存的视频url数组
 */
+(void)clearDiskCacheWithVideoUrlArray:(NSArray<NSURL *> *)videoUrlArray;

/**
 清除指定Url除外的视频本地缓存(异步)
 
 @param exceptVideoUrlArray 此url数组的视频缓存将被保留
 */
+(void)clearDiskCacheExceptVideoUrlArray:(NSArray<NSURL *> *)exceptVideoUrlArray;

/**
 *  获取XHLaunch本地缓存大小(M)
 */
+(float)diskCacheSize;

/**
 *  缓存路径
 */
+(NSString *)xhLaunchAdCachePath;
@end

