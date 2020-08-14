//
//  MobiHTTPNetworkTaskData.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/23.
//

#import "MobiHTTPNetworkTaskData.h"

@implementation MobiHTTPNetworkTaskData

- (instancetype)init {
    return [self initWithResponseHandler:nil errorHandler:nil shouldRedirectWithNewRequest:nil];
}

- (instancetype)initWithResponseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                           errorHandler:(void (^ _Nullable)(NSError * error))errorHandler
           shouldRedirectWithNewRequest:(BOOL (^ _Nullable)(NSURLSessionTask * task, NSURLRequest * newRequest))shouldRedirectWithNewRequest {
    if (self = [super init]) {
        _responseData = nil;
        _responseHandler = responseHandler;
        _errorHandler = errorHandler;
        _shouldRedirectWithNewRequest = shouldRedirectWithNewRequest;
    }

    return self;
}

@end
