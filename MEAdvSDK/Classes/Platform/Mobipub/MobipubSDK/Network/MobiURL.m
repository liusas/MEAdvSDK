//
//  MobiURL.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/24.
//

#import "MobiURL.h"

@interface MobiURL ()

@end

@implementation MobiURL

#pragma mark - Initialization

- (instancetype)initWithString:(NSString *)URLString {
    if (self = [super initWithString:URLString]) {
        _parameters = [NSMutableDictionary dictionary];
        _HTTPHeaders = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)URLWithString:(NSString *)URLString {
    return [[MobiURL alloc] initWithString:URLString];
}

+ (instancetype)URLWithComponents:(NSURLComponents *)components
                           params:(NSDictionary<NSString *, NSObject *> *)params {
    return [self URLWithComponents:components params:params HTTPMethod:@"GET" HTTPHeaders:nil];
}

+ (instancetype)URLWithComponents:(NSURLComponents *)components
                           params:(NSDictionary<NSString *, NSObject *> *)params
                       HTTPMethod:(NSString *)HTTPMethod {
    return [self URLWithComponents:components params:params HTTPMethod:HTTPMethod HTTPHeaders:nil];
}

+ (instancetype)URLWithComponents:(NSURLComponents *)components
                           params:(NSDictionary<NSString *,NSObject *> *)params
                       HTTPMethod:(NSString *)HTTPMethod
                      HTTPHeaders:(NSDictionary *)HTTPHeaders {
    NSString *urlStr = components.URL.absoluteString;
    MobiURL *mbURL = [[MobiURL alloc] initWithString:urlStr];
    if (HTTPMethod != nil) {
        mbURL.HTTPMethod = HTTPMethod;
    } else {
        mbURL.HTTPMethod = @"GET";
    }
    
    if (HTTPHeaders.count > 0) {
        mbURL.HTTPHeaders = [NSMutableDictionary dictionaryWithDictionary:HTTPHeaders];
    }
    [mbURL.parameters addEntriesFromDictionary:params];
    return mbURL;
}

@end
