//
//  MobiNativeExpressDrawView.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <UIKit/UIKit.h>

@class MobiNativeExpressDrawView;
@class MobiDrawViewAdReportModel;

@protocol MobiNativeExpressDrawViewDelegate <NSObject>

/*
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccessForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFailForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposureForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClickedForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView reportModel:(MobiDrawViewAdReportModel *)model;

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosedForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;


/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreenForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreenForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDissmissScreenForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDissmissScreenForDrawView:(MobiNativeExpressDrawView *)nativeExpressAdView;

@end


@interface MobiNativeExpressDrawView : UIView

/**
 * 代理
*/
@property (nonatomic, weak, readonly) id<MobiNativeExpressDrawViewDelegate> delegate;

/**
 * 是否渲染完毕
 */
@property (nonatomic, assign, readonly) BOOL isReady;

/**
 * 是否是视频模板广告
 */
@property (nonatomic, assign, readonly) BOOL isVideoAd;

/**
 *  viewControllerForPresentingModalView
 *  详解：[必选]开发者需传入用来弹出目标页的ViewController，一般为当前ViewController
 */
@property (nonatomic, weak) UIViewController *controller;

/**
 *  [必选]
 *  原生模板广告渲染
 */
- (void)render;

/**
 * 视频模板广告时长，单位 ms
 */
- (CGFloat)videoDuration;

/**
 * 视频模板广告已播放时长，单位 ms
 */
- (CGFloat)videoPlayTime;

/**
 返回广告的eCPM，单位：分
 
 @return 成功返回一个大于等于0的值，-1表示无权限或后台出现异常
 */
- (NSInteger)eCPM;

/**
 返回广告的eCPM等级
 
 @return 成功返回一个包含数字的string，@""或nil表示无权限或后台异常
 */
- (NSString *)eCPMLevel;


@end

/// 上报的数据模型
@interface MobiDrawViewAdReportModel : NSObject

@property(nonatomic,assign) CGPoint clickDownPoint;

@property(nonatomic,assign) CGPoint clickUpPoint;

@end
