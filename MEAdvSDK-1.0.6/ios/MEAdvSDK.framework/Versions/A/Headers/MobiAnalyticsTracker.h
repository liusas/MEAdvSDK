//
//  MobiAnalyticsTracker.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>

@class MobiConfig;

@protocol MobiAnalyticsTracker <NSObject>
/// 展现上报,内部做替换宏处理,__TS__
- (void)trackImpressionForConfiguration:(MobiConfig *)configuration;
/// 点击上报,内部做替换宏处理,__TS__,__DOWN_X__等
- (void)trackClickForConfiguration:(MobiConfig *)configuration;
/// 自由上报,内部不做替换宏处理,传入`NSURL`类型数组
- (void)sendTrackingRequestForURLs:(NSArray<NSURL *> *)URLs;
/// 自由上报,内部不做替换宏处理,传入`NSString`类型数组
- (void)sendTrackingRequestForURLStrs:(NSArray<NSString *> *)URLStrs;


/// 替换宏方法,返回`NSURL`类型数组
/// @param URLs 传入`NSURL`类型数组
/// @param clickDownPoint 手指按下时的横纵坐标,没有传 CGPointZero
/// @param clickUpPoint 手指抬起时的横纵坐标,没有传 CGPointZero
- (NSArray *)replaceMacroFromURLs:(NSArray <NSURL *>*)URLs withClickDownPoint:(CGPoint)clickDownPoint clickUpPoint:(CGPoint)clickUpPoint;

/// 替换宏方法,返回`NSURL`类型数组
/// @param URLStrings 传入`NSString`类型数组
/// @param clickDownPoint 手指按下时的横纵坐标,没有传 CGPointZero
/// @param clickUpPoint 手指抬起时的横纵坐标,没有传 CGPointZero
- (NSArray *)replaceMacroFromURLStrings:(NSArray <NSString *>*)URLStrings withClickDownPoint:(CGPoint)clickDownPoint clickUpPoint:(CGPoint)clickUpPoint;

/// 单个 url 字符串替换宏的方法
/// @param urlString 传入`NSString`类型字符串
/// @param clickDownPoint 手指按下时的横纵坐标,没有传 CGPointZero
/// @param clickUpPoint 手指抬起时的横纵坐标,没有传 CGPointZero
- (NSString *)replaceMacroFromUrlString:(NSMutableString *)urlString withClickDownPoint:(CGPoint)clickDownPoint clickUpPoint:(CGPoint)clickUpPoint;
@end

@interface MobiAnalyticsTracker : NSObject

+ (MobiAnalyticsTracker *)sharedTracker;

@end

@interface MobiAnalyticsTracker (MobiAnalyticsTracker) <MobiAnalyticsTracker>
@end
