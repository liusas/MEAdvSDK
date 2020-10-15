//
//  MobiURL.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/24.
//

#import <Foundation/Foundation.h>

@interface MobiURL : NSURL

/// 请求方法,`NSString`类型的`POST`,`GET`等
/// 默认是`GET`请求
@property (nonatomic, copy) NSString *HTTPMethod;
@property (nonatomic, copy) NSMutableDictionary *HTTPHeaders;
/// 请求参数
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSObject *> * parameters;

+ (instancetype)URLWithComponents:(NSURLComponents *)components
                           params:(NSDictionary<NSString *, NSObject *> *)params;

+ (instancetype)URLWithComponents:(NSURLComponents *)components
                           params:(NSDictionary<NSString *, NSObject *> *)params
                       HTTPMethod:(NSString *)HTTPMethod;

+ (instancetype)URLWithComponents:(NSURLComponents *)components
                           params:(NSDictionary<NSString *, NSObject *> *)params
                       HTTPMethod:(NSString *)HTTPMethod
                      HTTPHeaders:(NSDictionary *)HTTPHeaders;



@end
