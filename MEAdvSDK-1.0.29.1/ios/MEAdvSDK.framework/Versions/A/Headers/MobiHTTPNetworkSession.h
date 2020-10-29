//
//  MobiHTTPNetworkSession.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobiHTTPNetworkSession : NSObject

/**
 Singleton instance of @c MPHTTPNetworkSession.
 */
+ (instancetype)sharedInstance;

/// 初始化一个网络请求,但这个网络请求不是立即发送,可由调用方主动用task发送
/// @param request 待发送的请求request,请求内包括url,若get请求则参数拼接在url上,post请求则是添加到httpBody中,统一在MobiRequest中处理
/// @param responseHandler 请求成功的回调,返回NSData类型的数据
/// @param errorHandler 请求失败的回调
/// @param shouldRedirectWithNewRequest 支持deeplink重定向
+ (NSURLSessionTask *)taskWithHttpRequest:(NSURLRequest *)request
                          responseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                             errorHandler:(void (^ _Nullable)(NSError * error))errorHandler
             shouldRedirectWithNewRequest:(BOOL (^ _Nullable)(NSURLSessionTask * task, NSURLRequest * newRequest))shouldRedirectWithNewRequest;

/// 初始化一个网络请求,并立刻发送
/// @param request 待发送的请求request,请求内包括url,若get请求则参数拼接在url上,post请求则是添加到httpBody中,统一在MobiRequest中处理
+ (NSURLSessionTask *)startTaskWithHttpRequest:(NSURLRequest *)request;

/// 初始化一个网络请求,并立刻用发送
/// @param request 待发送的请求request,请求内包括url,若get请求则参数拼接在url上,post请求则是添加到httpBody中,统一在MobiRequest中处理
/// @param responseHandler 请求成功的回调,返回NSData类型的数据
/// @param errorHandler 请求失败的回调
+ (NSURLSessionTask *)startTaskWithHttpRequest:(NSURLRequest *)request
                               responseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                                  errorHandler:(void (^ _Nullable)(NSError * error))errorHandler;

/// 初始化一个网络请求,并立刻用发送
/// @param request 待发送的请求request,请求内包括url,若get请求则参数拼接在url上,post请求则是添加到httpBody中,统一在MobiRequest中处理
/// @param responseHandler 请求成功的回调,返回NSData类型的数据
/// @param errorHandler 请求失败的回调
/// @param shouldRedirectWithNewRequest 支持deeplink重定向
+ (NSURLSessionTask *)startTaskWithHttpRequest:(NSURLRequest *)request
                               responseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                                  errorHandler:(void (^ _Nullable)(NSError * error))errorHandler
                  shouldRedirectWithNewRequest:(BOOL (^ _Nullable)(NSURLSessionTask * task, NSURLRequest * newRequest))shouldRedirectWithNewRequest;

@end

NS_ASSUME_NONNULL_END
