//
//  MobiHTTPNetworkTaskData.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobiHTTPNetworkTaskData : NSObject

@property (nonatomic, strong, nullable) NSMutableData * responseData;
@property (nonatomic, copy, nullable) void (^responseHandler)(NSData * data, NSHTTPURLResponse * response);
@property (nonatomic, copy, nullable) void (^errorHandler)(NSError * error);
@property (nonatomic, copy, nullable) BOOL (^shouldRedirectWithNewRequest)(NSURLSessionTask * task, NSURLRequest * newRequest);

/// 初始化MobiHTTPNetworkTaskData,这个类用于保存MobiHTTPNetworkSession中的各个回调
/// @param responseHandler 网络请求回调内容,于当前线程调用
/// @param errorHandler 网络请求的错误回调,于当前线程调用
/// @param shouldRedirectWithNewRequest 若出现重定向,则会在当前线程调用重定向回调
- (instancetype)initWithResponseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                           errorHandler:(void (^ _Nullable)(NSError * error))errorHandler
           shouldRedirectWithNewRequest:(BOOL (^ _Nullable)(NSURLSessionTask * task, NSURLRequest * newRequest))shouldRedirectWithNewRequest NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
