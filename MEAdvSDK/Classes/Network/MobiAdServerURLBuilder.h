//
//  MobiAdServerURLBuilder.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/22.
//

#import <Foundation/Foundation.h>
#import "MobiAdTargeting.h"

@class MobiURL;

NS_ASSUME_NONNULL_BEGIN
// 配置广告请求的URL和参数,
@interface MobiAdServerURLBuilder : NSObject

/// 网络请求,默认GET请求
/// @param endpointPath url中除了baseurl的部分
/// @param parameters 参数
+ (MobiURL *)URLWithEndpointPath:(NSString *)endpointPath params:(NSDictionary *)parameters;

/// 网络请求
/// @param endpointPath url中除了baseurl的部分
/// @param parameters 参数
/// @param HTTPMethod 请求方法,POST,GET等,默认GET请求
+ (MobiURL *)URLWithEndpointPath:(NSString *)endpointPath params:(NSDictionary *)parameters HTTPMethod:(NSString *)HTTPMethod;

/// 网络请求
/// @param endpointPath url中除了baseurl的部分
/// @param parameters 参数
/// @param HTTPMethod 请求方法,POST,GET等,默认GET请求
/// @param HTTPHeaders 请求头
+ (MobiURL *)URLWithEndpointPath:(NSString *)endpointPath params:(NSDictionary *)parameters HTTPMethod:(NSString *)HTTPMethod HTTPHeaders:(NSDictionary *)HTTPHeaders;

/// 广告配置请求
/// @param posid 广告位id
/// @param targeting 一些能让广告投放更精准的参数,可为nil
+ (MobiURL *)URLWithAdPosid:(NSString *)posid targeting:(MobiAdTargeting *)targeting;

@end

NS_ASSUME_NONNULL_END
