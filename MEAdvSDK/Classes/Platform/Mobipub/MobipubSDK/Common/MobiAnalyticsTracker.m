//
//  MobiAnalyticsTracker.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MobiAnalyticsTracker.h"
#import "MobiConfig.h"
#import "MobiHTTPNetworkSession.h"
//#import "MPLogging.h"
#import "MobiURLRequest.h"
#import "MPConstants.h"
#import "NSDate+MPAdditions.h"

/// 默认空坐标
static CGFloat kDefaultCoordinateError = -999.0;

@implementation MobiAnalyticsTracker

+ (MobiAnalyticsTracker *)sharedTracker
{
    static MobiAnalyticsTracker * sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[self alloc] init];
    });
    return sharedTracker;
}

@end

@implementation MobiAnalyticsTracker (MobiAnalyticsTracker)

// MARK: - 处理 URL
- (void)trackImpressionForConfiguration:(MobiConfig *)configuration {
    // Take the @c impressionTrackingURLs array from @c configuration and use the @c sendTrackingRequestForURLs method
    // to actually send the requests.
//    MPLogDebug(@"Tracking impression: %@", configuration.impressionTrackingURLs.firstObject);
    [self sendTrackingRequestForURLs:[self replaceMacroFromURLs:configuration.impressionTrackingURLs withClickDownPoint:CGPointZero clickUpPoint:CGPointZero]];
}

- (void)trackClickForConfiguration:(MobiConfig *)configuration {
    [self sendTrackingRequestForURLs:[self replaceMacroFromURLs:configuration.clickTrackingURLs withClickDownPoint:configuration.clickDownPoint clickUpPoint:configuration.clickUpPoint]];
}

- (void)sendTrackingRequestForURLs:(NSArray<NSURL *> *)URLs {
    for (NSURL *URL in URLs) {
        if (URL.absoluteString == nil || [URL.absoluteString isEqualToString:@""]) {
            continue;
        }
        MobiURLRequest * trackingRequest = [[MobiURLRequest alloc] initWithURL:URL];
        [MobiHTTPNetworkSession startTaskWithHttpRequest:trackingRequest];
    }
}

// 替换宏
- (NSArray *)replaceMacroFromURLs:(NSArray <NSURL *>*)URLs withClickDownPoint:(CGPoint)clickDownPoint clickUpPoint:(CGPoint)clickUpPoint {
    NSMutableArray <NSURL *>*urls = [NSMutableArray array];
    
    for (NSURL *URL in URLs) {
        if (URL.absoluteString == nil || [URL.absoluteString isEqualToString:@""]) {
            continue;
        }
        
        NSMutableString *urlStr = [[NSMutableString alloc] initWithString:URL.absoluteString];
        urlStr = [self replaceMacroFromUrlString:urlStr withClickDownPoint:clickDownPoint clickUpPoint:clickUpPoint];
        
        [urls addObject:[NSURL URLWithString:urlStr]];
    }
    
    return urls;
}

// MARK: - 处理 String
- (void)sendTrackingRequestForURLStrs:(NSArray<NSString *> *)URLStrs {
    for (NSString *URLStr in URLStrs) {
        if (URLStr == nil || [URLStr isEqualToString:@""]) {
            continue;
        }
        MobiURLRequest * trackingRequest = [[MobiURLRequest alloc] initWithURL:[NSURL URLWithString:URLStr]];
        [MobiHTTPNetworkSession startTaskWithHttpRequest:trackingRequest];
    }
}

/// 替换宏,返回数组
- (NSArray *)replaceMacroFromURLStrings:(NSArray <NSString *>*)URLStrings withClickDownPoint:(CGPoint)clickDownPoint clickUpPoint:(CGPoint)clickUpPoint {
    NSMutableArray <NSURL *>*urls = [NSMutableArray array];
    
    for (NSString *urlStr in URLStrings) {
        if (urlStr == nil || [urlStr isEqualToString:@""]) {
            continue;
        }
        
        NSMutableString *mutUrlStr = [[NSMutableString alloc] initWithString:urlStr];
        mutUrlStr = [self replaceMacroFromUrlString:mutUrlStr withClickDownPoint:clickDownPoint clickUpPoint:clickUpPoint];
        
        [urls addObject:[NSURL URLWithString:mutUrlStr]];
    }
    
    return urls;
}


// 替换宏
- (NSString *)replaceMacroFromUrlString:(NSMutableString *)urlString withClickDownPoint:(CGPoint)clickDownPoint clickUpPoint:(CGPoint)clickUpPoint {
    if ([urlString containsString:__TS__]) {
        // 替换时间出发时间戳
        urlString = [urlString stringByReplacingOccurrencesOfString:__TS__ withString:[NSDate getNowTimeMillionsecond]];
    }
    
    CGFloat dx = clickDownPoint.x;
    CGFloat dy = clickDownPoint.y;
    CGFloat ux = clickUpPoint.x;
    CGFloat uy = clickUpPoint.y;
    
    if (CGPointEqualToPoint(clickDownPoint, CGPointZero) || CGPointEqualToPoint(clickUpPoint, CGPointZero)) {
        dx = kDefaultCoordinateError;
        dy = kDefaultCoordinateError;
        ux = kDefaultCoordinateError;
        uy = kDefaultCoordinateError;
    }
    
    if ([urlString containsString:__DOWN_X__]) {
        // 替换按下的 x 坐标
        urlString = [urlString stringByReplacingOccurrencesOfString:__DOWN_X__ withString:[NSString stringWithFormat:@"%.f", dx]];
    }
    
    if ([urlString containsString:__DOWN_Y__]) {
        // 替换按下的 y 坐标
        urlString = [urlString stringByReplacingOccurrencesOfString:__DOWN_Y__ withString:[NSString stringWithFormat:@"%.f", dy]];
    }
    
    if ([urlString containsString:__UP_X__]) {
        // 替换抬起的 x 坐标
        urlString = [urlString stringByReplacingOccurrencesOfString:__UP_X__ withString:[NSString stringWithFormat:@"%.f", ux]];
    }
    
    if ([urlString containsString:__UP_Y__]) {
        // 替换抬起的 y 坐标
        urlString = [urlString stringByReplacingOccurrencesOfString:__UP_Y__ withString:[NSString stringWithFormat:@"%.f", uy]];
    }
    
    return urlString;
}

@end
