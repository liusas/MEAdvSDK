//
//  MPEnhancedDeeplinkRequest.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>

@interface MPEnhancedDeeplinkRequest : NSObject

@property (copy) NSURL *originalURL;

// Request components derived from the original URL.
/// deeplink 地址
@property (copy) NSURL *primaryURL;
/// deeplink 调起成功上报地址
@property (strong) NSArray <NSString *>*primaryTrackingURLs;
/// deeplink 失败后的备选 url,这里是 curl
@property (copy) NSURL *fallbackURL;
/// deeplink 失败后的备选 url,这里是 nil
@property (strong) NSArray <NSString *>*fallbackTrackingURLs;

- (instancetype)initWithURL:(NSURL *)URL;

/// 初始化deeplink请求的各URL配置
/// @param primaryURL 用于启动app的URL
/// @param originalURL 初始可跳转链接的URL
/// @param fallbackURL 备用URL,即未打开app,就调它去appstore下载
/// @param primaryTrackingURLs 启动app成功后上报的url数组
/// @param fallbackTrackingURLs 成功调起appstore后上报的url数组
- (instancetype)initWithPrimaryURL:(NSURL *)primaryURL originalURL:(NSURL *)originalURL fallbackURL:(NSURL *)fallbackURL primaryTrackingURLs:(NSArray *)primaryTrackingURLs fallbackTrackingURLs:(NSArray *)fallbackTrackingURLs;

@end
