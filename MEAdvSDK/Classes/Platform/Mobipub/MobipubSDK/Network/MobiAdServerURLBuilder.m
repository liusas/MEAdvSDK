//
//  MobiAdServerURLBuilder.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/22.
//

#import "MobiAdServerURLBuilder.h"
#import "MobiAPIEndpoints.h"
#import "MobiURL.h"
#import "MPConstants.h"
#import "MPIdentityProvider.h"
#import "MPDeviceInformation.h"
#import "MobiGlobal.h"
#import "MPWebBrowserUserAgentInfo.h"

@implementation MobiAdServerURLBuilder

+ (MobiURL *)URLWithEndpointPath:(NSString *)endpointPath params:(NSDictionary *)parameters {
    return [self URLWithEndpointPath:endpointPath params:parameters HTTPMethod:nil];
}

+ (MobiURL *)URLWithEndpointPath:(NSString *)endpointPath params:(NSDictionary *)parameters HTTPMethod:(NSString *)HTTPMethod {
    return [self URLWithEndpointPath:endpointPath params:parameters HTTPMethod:HTTPMethod HTTPHeaders:nil];
}

+ (MobiURL *)URLWithEndpointPath:(NSString *)endpointPath params:(NSDictionary *)parameters HTTPMethod:(NSString *)HTTPMethod HTTPHeaders:(NSDictionary *)HTTPHeaders {
    NSURLComponents * components = [MobiAPIEndpoints baseURLComponentsWithPath:endpointPath];
    return [MobiURL URLWithComponents:components params:parameters HTTPMethod:HTTPMethod HTTPHeaders:HTTPHeaders];
}

/// 拼接参数,和网络请求的末端endpoint
+ (MobiURL *)URLWithAdPosid:(NSString *)posid targeting:(MobiAdTargeting *)targeting {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"tag"] = @(3);
    params[@"posid"] = posid;
    params[@"sdkver"] = MP_SDK_VERSION;
#warning 当前写死了,后续改过来
    params[@"idfa"] = [MPDeviceInformation idfa];//@"95955F33-BFBD-48BA-A630-866D2DAE482D";
    params[@"imei"] = @"";
    params[@"oaid"] = @"";
    params[@"androidid"] = @"";
    params[@"mac"] = @"";
    params[@"lan"] = [MPDeviceInformation localIdentifier];
    params[@"mak"] = @"apple";
    params[@"mod"] = [MPDeviceInformation getDeviceModel];
    params[@"cver"] = [MPDeviceInformation appVersion];
    params[@"bundle"] = [MPDeviceInformation appBundleID];
    params[@"mcc"] = [MPDeviceInformation mobileCountryCode];
    params[@"mnc"] = [MPDeviceInformation mobileNetworkCode];
    params[@"nt"] = [MPDeviceInformation network];
    params[@"os"] = @"iOS";
    params[@"osv"] = [MPDeviceInformation systemVersion];
    params[@"lat"] = [MPDeviceInformation lat];
    params[@"lon"] = [MPDeviceInformation lon];
    params[@"res"] = [NSString stringWithFormat:@"%.f*%.f", MPScreenResolution().width, MPScreenResolution().height];
    params[@"ua"] = [MPWebBrowserUserAgentInfo userAgent];
    
    return [self URLWithEndpointPath:Mobi_API_PATH_AD_REQUEST params:params HTTPMethod:@"GET" HTTPHeaders:nil];
}

@end
