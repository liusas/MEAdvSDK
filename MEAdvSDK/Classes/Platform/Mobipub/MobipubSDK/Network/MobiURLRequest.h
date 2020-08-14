//
//  MobiURLRequest.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobiURLRequest : NSMutableURLRequest

/// 初始化网络请求用的request,在这其中会配置timeInterval超时时间及NSURLRequestCachePolicy缓存策略
/// 实例方法
/// @param URL 请求广告时传入MobiURL的实例
- (instancetype)initWithURL:(NSURL *)URL;

/// 初始化网络请求用的request,在这其中会配置timeInterval超时时间及NSURLRequestCachePolicy缓存策略
/// 类方法
/// @param URL 请求广告时传入MobiURL的实例
+ (MobiURLRequest *)requestWithURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
