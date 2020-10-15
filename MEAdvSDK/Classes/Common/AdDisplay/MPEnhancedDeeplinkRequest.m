//
//  MPEnhancedDeeplinkRequest.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPEnhancedDeeplinkRequest.h"
#import "NSURL+MPAdditions.h"

static NSString * const kRequiredHostname = @"navigate";
static NSString * const kPrimaryURLKey = @"primaryUrl";
static NSString * const kPrimaryTrackingURLKey = @"primaryTrackingUrl";
static NSString * const kFallbackURLKey = @"fallbackUrl";
static NSString * const kFallbackTrackingURLKey = @"fallbackTrackingUrl";

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPEnhancedDeeplinkRequest

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        if (![[[URL host] lowercaseString] isEqualToString:kRequiredHostname]) {
            return nil;
        }

        NSString *primaryURLString = [URL mp_queryParameterForKey:kPrimaryURLKey];
        if (![primaryURLString length]) {
            return nil;
        }
        _primaryURL = [NSURL URLWithString:primaryURLString];
        _originalURL = [URL copy];

        NSMutableArray *primaryTrackingURLs = [NSMutableArray array];
        NSArray *primaryTrackingURLStrings = [URL mp_queryParametersForKey:kPrimaryTrackingURLKey];
        for (NSString *URLString in primaryTrackingURLStrings) {
            [primaryTrackingURLs addObject:[NSURL URLWithString:URLString]];
        }
        _primaryTrackingURLs = [NSArray arrayWithArray:primaryTrackingURLs];

        NSString *fallbackURLString = [URL mp_queryParameterForKey:kFallbackURLKey];
        _fallbackURL = [NSURL URLWithString:fallbackURLString];

        NSMutableArray *fallbackTrackingURLs = [NSMutableArray array];
        NSArray *fallbackTrackingURLStrings = [URL mp_queryParametersForKey:kFallbackTrackingURLKey];
        for (NSString *URLString in fallbackTrackingURLStrings) {
            [fallbackTrackingURLs addObject:[NSURL URLWithString:URLString]];
        }
        _fallbackTrackingURLs = [NSArray arrayWithArray:fallbackTrackingURLs];
    }
    return self;
}

/// 初始化deeplink请求的各URL配置
/// @param primaryURL 用于启动app的URL
/// @param originalURL 初始可跳转链接的URL
/// @param fallbackURL 备用URL,即未打开app,就调它去appstore下载
/// @param primaryTrackingURLs 启动app成功后上报的url数组
/// @param fallbackTrackingURLs 成功调起appstore后上报的url数组
- (instancetype)initWithPrimaryURL:(NSURL *)primaryURL originalURL:(NSURL *)originalURL fallbackURL:(NSURL *)fallbackURL primaryTrackingURLs:(NSArray *)primaryTrackingURLs fallbackTrackingURLs:(NSArray *)fallbackTrackingURLs {
    if (self = [super init]) {
        if (primaryURL != nil) {
            _primaryURL = [primaryURL copy];
        }
        
        if (originalURL != nil) {
            _originalURL = [originalURL copy];
        }
        
        if (fallbackURL != nil) {
            _fallbackURL = [fallbackURL copy];
        }
        
        if (primaryTrackingURLs.count > 0) {
            _primaryTrackingURLs = [NSArray arrayWithArray:primaryTrackingURLs];
        }
        
        if (fallbackTrackingURLs.count > 0) {
            _fallbackTrackingURLs = [NSArray arrayWithArray:fallbackTrackingURLs];
        }
    }
    return self;
}

@end
