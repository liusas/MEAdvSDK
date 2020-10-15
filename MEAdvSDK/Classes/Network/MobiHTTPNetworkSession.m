//
//  MobiHTTPNetworkSession.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/23.
//

#import "MobiHTTPNetworkSession.h"
#import "MobiHTTPNetworkTaskData.h"
#import "NSError+MPAdditions.h"
#import "MPError.h"

#define safe_block(block, ...) block ? block(__VA_ARGS__) : nil
#define async_queue_block(queue, block, ...) dispatch_async(queue, ^ \
{ \
safe_block(block, __VA_ARGS__); \
})
#define main_queue_block(block, ...) async_queue_block(dispatch_get_main_queue(), block, __VA_ARGS__);

@interface MobiHTTPNetworkSession ()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession * sharedSession;

// 存放NSURLSession实例的字典,由于NSMutableDictionary并不是线程安全的,需要创建一个队列确保并行读取,串行写入
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask *, MobiHTTPNetworkTaskData *> * sessions;
@property (nonatomic, strong) dispatch_queue_t sessionsQueue;

@end

@implementation MobiHTTPNetworkSession

// MARK: - Initialization

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id _sharedInstance;
    dispatch_once(&once, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        // Shared `NSURLSession` to be used for all `MPHTTPNetworkTask` objects. All tasks should use this single
        // session so that the DNS lookup and SSL handshakes do not need to be redone.
        _sharedSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];

        // Dictionary of all sessions currently in flight.
        _sessions = [NSMutableDictionary dictionary];
        _sessionsQueue = dispatch_queue_create("com.mopub.mopub-ios-sdk.mphttpnetworksession.queue", DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
}

// MARK: - Access

/// 将taskData存储到sessions字典里,为了保证存储时线程安全,使用dispatch_barrier_sync函数,保证在这次存储时,不会对sessions有任何存取操作
/// @param data taskData,包含responseData,responseHandler,errorHandler,shouldRedirectWithNewRequest
/// @param task key值,每次请求的task
- (void)setSessionData:(MobiHTTPNetworkTaskData *)data forTask:(NSURLSessionTask *)task {
    dispatch_barrier_sync(self.sessionsQueue, ^{
        self.sessions[task] = data;
    });
}

/// 从sessions字典中取出以task为key的taskData,为了保证存储时线程安全,使用dispatch_barrier_sync函数,保证在这次存储时,不会对sessions有任何存取操作
/// @param task 发送请求是的NSURLSessionTask实例
- (MobiHTTPNetworkTaskData *)sessionDataForTask:(NSURLSessionTask *)task {
    __block MobiHTTPNetworkTaskData * data = nil;
    dispatch_sync(self.sessionsQueue, ^{
        data = self.sessions[task];
    });

    return data;
}

/**
 Appends additional data to the @c responseData field of @c MPHTTPNetworkTaskData in
 a thread safe manner.
 @param data New data to append.
 @param task Task to append the data to.
 */

/// 请求回来的数据添加到taskData到的responseData中,这个过程是线程安全的
/// @param data 返回的数据
/// @param task 这次请求的task
- (void)appendData:(NSData *)data toSessionDataForTask:(NSURLSessionTask *)task {
    // data为空或task为空时,没办法保存
    if (data == nil || task == nil) {
        return;
    }

    dispatch_barrier_sync(self.sessionsQueue, ^{
        MobiHTTPNetworkTaskData * taskData = self.sessions[task];
        // 若taskData为空,则不作处理
        if (taskData == nil) {
            return;
        }

        // 若responseData暂时没有值,就创建一个
        if (taskData.responseData == nil) {
            taskData.responseData = [NSMutableData data];
        }

        [taskData.responseData appendData:data];
    });
}

// MARK: - Public task request
+ (NSURLSessionTask *)taskWithHttpRequest:(NSURLRequest *)request
                          responseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                             errorHandler:(void (^ _Nullable)(NSError * error))errorHandler
             shouldRedirectWithNewRequest:(BOOL (^ _Nullable)(NSURLSessionTask * task, NSURLRequest * newRequest))shouldRedirectWithNewRequest {
    NSURLSessionDataTask *task = [MobiHTTPNetworkSession.sharedInstance.sharedSession dataTaskWithRequest:request];
    
    // 把responseHandler,errorHandler,shouldRedirectWithNewRequest回调实例化成MobiHTTPNetworkTaskData,供NSURLSessionDataDelegate回调中灵活取用
    MobiHTTPNetworkTaskData *taskData = [[MobiHTTPNetworkTaskData alloc] initWithResponseHandler:responseHandler errorHandler:errorHandler shouldRedirectWithNewRequest:shouldRedirectWithNewRequest];
    
    // 以task为key,以taskData为value存储到我们处理过的线程安全的字典里
    [MobiHTTPNetworkSession.sharedInstance setSessionData:taskData forTask:task];
    return task;
}

/// 初始化一个网络请求,并立刻发送
/// @param request 待发送的请求request,请求内包括url,若get请求则参数拼接在url上,post请求则是添加到httpBody中,统一在MobiRequest中处理
+ (NSURLSessionTask *)startTaskWithHttpRequest:(NSURLRequest *)request {
    return [self startTaskWithHttpRequest:request responseHandler:nil errorHandler:nil shouldRedirectWithNewRequest:nil];
}

/// 初始化一个网络请求,并立刻用发送
/// @param request 待发送的请求request,请求内包括url,若get请求则参数拼接在url上,post请求则是添加到httpBody中,统一在MobiRequest中处理
/// @param responseHandler 请求成功的回调,返回NSData类型的数据
/// @param errorHandler 请求失败的回调
+ (NSURLSessionTask *)startTaskWithHttpRequest:(NSURLRequest *)request
                               responseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                                  errorHandler:(void (^ _Nullable)(NSError * error))errorHandler {
    return [self startTaskWithHttpRequest:request responseHandler:responseHandler errorHandler:errorHandler shouldRedirectWithNewRequest:nil];
}

/// 初始化一个网络请求,并立刻用发送
/// @param request 待发送的请求request,请求内包括url,若get请求则参数拼接在url上,post请求则是添加到httpBody中,统一在MobiRequest中处理
/// @param responseHandler 请求成功的回调,返回NSData类型的数据
/// @param errorHandler 请求失败的回调
/// @param shouldRedirectWithNewRequest 支持deeplink重定向
+ (NSURLSessionTask *)startTaskWithHttpRequest:(NSURLRequest *)request
                               responseHandler:(void (^ _Nullable)(NSData * data, NSHTTPURLResponse * response))responseHandler
                                  errorHandler:(void (^ _Nullable)(NSError * error))errorHandler
                  shouldRedirectWithNewRequest:(BOOL (^ _Nullable)(NSURLSessionTask * task, NSURLRequest * newRequest))shouldRedirectWithNewRequest {
    // 初始化一个task,并将回调存储到MobiHTTPNetworkTaskData
    NSURLSessionTask *task = [self taskWithHttpRequest:request responseHandler:responseHandler errorHandler:errorHandler shouldRedirectWithNewRequest:shouldRedirectWithNewRequest];
    // 立刻发送请求
    [task resume];
    
    return task;
}

// MARK: - NSURLSessionDataDelegate
/**
 *  请求已经收到了服务器的response headers应答,
 *  在调用completionHandler之前不会再收到其他响应,不实现这个方法时,默认都是allow,然后继续下面的数据回调
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    // 允许所有请求,让请求继续
    completionHandler(NSURLSessionResponseAllow);
}


/// 网络请求已经返回数据时回调,该请求可能会回调多次,但只会回调上次发起的请求返回的数据,所以应该将数据根据不同dataTask累加起来
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self appendData:data toSessionDataForTask:dataTask];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 从全局字典中找出此次请求对应的taskData
    MobiHTTPNetworkTaskData * taskData = [self sessionDataForTask:task];
    if (taskData == nil) {
        return;
    }

    // 删除字典中对应的此次请求taskData
    [self setSessionData:nil forTask:task];

    // 该请求返回的结果是正确的还是错误的
    if (error != nil) {
//        MPLogEvent([MPLogEvent error:error message:nil]);
        safe_block(taskData.errorHandler, error);
        return;
    }

    // 确认返回的response是否是有效的HTTP请求的返回
    NSHTTPURLResponse * httpResponse = [task.response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)task.response : nil;
    if (httpResponse == nil) {
        NSError * notHttpResponseError = [NSError networkResponseIsNotHTTP];
//        MPLogEvent([MPLogEvent error:notHttpResponseError message:nil]);
        safe_block(taskData.errorHandler, notHttpResponseError);
        return;
    }

    // 确认返回的code不是一个错误码,大于400的都是错误码
    // See https://en.wikipedia.org/wiki/List_of_HTTP_status_codes for all valid status codes.
    if (httpResponse.statusCode >= 400) {
        NSError * not200ResponseError = [NSError networkErrorWithHTTPStatusCode:httpResponse.statusCode];
//        MPLogEvent([MPLogEvent error:not200ResponseError message:nil]);
        safe_block(taskData.errorHandler, not200ResponseError);
        return;
    }

    // 确认我们保存的responseData中有服务端返回的数据
    if (taskData.responseData == nil) {
        NSError * noDataError = [NSError networkResponseContainedNoData];
//        MPLogEvent([MPLogEvent error:noDataError message:nil]);
        safe_block(taskData.errorHandler, noDataError);
        return;
    }

    // 至此,回调请求成功的信息
    safe_block(taskData.responseHandler, taskData.responseData, httpResponse);
}

// MARK: - NSURLSessionTaskDelegate
/// 处理重定向deeplink,completionHandler回调哪个请求,就会重定向到哪个request,当然我们也可以自定义
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    MobiHTTPNetworkTaskData * taskData = [self sessionDataForTask:task];
    if (taskData == nil) {
        completionHandler(request);
        return;
    }

    // 如果有设置重定向的处理block(shouldRedirectWithNewRequest),则重定向是被允许的
    NSURLRequest * newRequest = request;
    if (taskData.shouldRedirectWithNewRequest != nil && !taskData.shouldRedirectWithNewRequest(task, request)) {
        // 设置request为nil,则表示拒绝重定向
        newRequest = nil;
    }
    
    completionHandler(newRequest);
}

@end
