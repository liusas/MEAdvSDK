//
//  MobiAPIEndpoints.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/23.
//

#import "MobiAPIEndpoints.h"

// URL scheme constants
static NSString * const kUrlSchemeHttp = @"http";
static NSString * const kUrlSchemeHttps = @"https";

#warning base host url
// Base URL constant
//static NSString * const kMobiBaseHostname = @"39.100.153.141";
static NSString * const kMobiBaseHostname = @"ads.mycrtb.com";

@implementation MobiAPIEndpoints

#pragma mark - setUsesHTTPS

static BOOL sUsesHTTPS = NO;
+ (void)setUsesHTTPS:(BOOL)usesHTTPS {
    sUsesHTTPS = usesHTTPS;
}

static NSString * _baseHostname = nil;
+ (void)setBaseHostname:(NSString *)baseHostname {
    _baseHostname = baseHostname;
}

+ (NSString *)baseHostname {
    if (_baseHostname == nil || [_baseHostname isEqualToString:@""]) {
        return kMobiBaseHostname;
    }
    
    return _baseHostname;
}

+ (NSString *)baseURL {
//    if (MPDeviceInformation.appTransportSecuritySettings == MPATSSettingEnabled) {
//        return [@"https://" stringByAppendingString:self.baseHostname];
//    }
    return [@"http://" stringByAppendingString:self.baseHostname];
}

+ (NSURLComponents *)baseURLComponentsWithPath:(NSString *)path {
    
    NSURLComponents * components = [[NSURLComponents alloc] init];
//    components.scheme = (sUsesHTTPS ? kUrlSchemeHttps : kUrlSchemeHttp);
    components.scheme = @"http";
    components.host = self.baseHostname;
    components.path = path;
#warning 测试先这么写,正式用上面的
//    NSURLComponents *components = [NSURLComponents new];
//    components.scheme = @"http";
//    components.host = @"47.114.88.192";
//    components.path = @"/mbid";
//    components.port = @(9088);
//    components.host = @"47.114.88.192";
//    components.port = @(9088);
//    components.path = @"/mbid";
    return components;
}

@end
