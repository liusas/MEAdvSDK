//
//  MobiAdConfigServer.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/6.
//

#import "MobiAdConfigServer.h"
#import "MobiPub.h"
#import "MobiConfig.h"
#import "MobiAPIEndpoints.h"
//#import "MPConsentManager.h"
//#import "MPCoreInstanceProvider.h"
#import "MPError.h"
#import "MobiHTTPNetworkSession.h"
//#import "MPLogging.h"
//#import "MPRateLimitManager.h"
#import "MobiURLRequest.h"

@interface MobiAdConfigServer ()

@property (nonatomic, assign) BOOL loading;
@property (nonatomic, strong) NSURLSessionTask * task;
@property (nonatomic, strong) NSDictionary *responseHeaders;

@property (nonatomic, readonly) BOOL isRateLimited;

@end

@implementation MobiAdConfigServer

- (id)initWithDelegate:(id<MobiAdConfigServerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [self.task cancel];
}

#pragma mark - Public

- (void)loadURL:(NSURL *)URL {
    if (self.isRateLimited) {
        [self didFailWithError:[NSError tooManyRequests]];
        return;
    }
    
    [self cancel];
    
    // 在开始加载之前,删除所有cookies
    [self removeAllMoPubCookies];
    
    // 判断SDK是否已经初始化,若没初始化不允许加载
//    if (!MobiPub.sharedInstance.isSdkInitialized) {
//        [self failLoadForSDKInit];
//        return;
//    }
    
    // Generate request
    MobiURLRequest * request = [[MobiURLRequest alloc] initWithURL:URL];
    //    MPLogEvent([MPLogEvent adRequestedWithRequest:request]);
    
    __weak __typeof__(self) weakSelf = self;
    self.task = [MobiHTTPNetworkSession startTaskWithHttpRequest:request responseHandler:^(NSData * data, NSHTTPURLResponse * response) {
        // Capture strong self for the duration of this block.
        __typeof__(self) strongSelf = weakSelf;
        
        // Handle the response.
        [strongSelf didFinishLoadingWithData:data];
    } errorHandler:^(NSError * error) {
        // Capture strong self for the duration of this block.
        __typeof__(self) strongSelf = weakSelf;
        
        // Handle the error.
        [strongSelf didFailWithError:error];
    }];
    
    self.loading = YES;
}

- (void)cancel
{
    self.loading = NO;
    [self.task cancel];
    self.task = nil;
}

- (void)failLoadForSDKInit {
    NSError *error = [NSError adLoadFailedBecauseSdkNotInitialized];
//    MPLogEvent([MPLogEvent error:error message:nil]);
    [self didFailWithError:error];
}

#pragma mark - Handlers

- (void)didFailWithError:(NSError *)error {
    // Do not record a logging event if we failed.
    self.loading = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate communicatorDidFailWithError:error];
    });
}

- (void)didFinishLoadingWithData:(NSData *)data {
    // In the event that the @c adUnitIdUsedForConsent from @c MPConsentManager is @c nil or malformed,
    // we should populate it with this known good adunit ID. This is to cover any edge case where the
    // publisher manages to initialize with no adunit ID or a malformed adunit ID.
    // It is known good since this is the success callback from the ad request.
//    [MPConsentManager.sharedManager setAdUnitIdUsedForConsent:self.delegate.adUnitId isKnownGood:YES];

    self.loading = NO;
    
    NSError * error = nil;
    NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) {
        NSError * parseError = [NSError adResponseFailedToParseWithError:error];
//        MPLogEvent([MPLogEvent error:parseError message:nil]);
        [self didFailWithError:parseError];
        return;
    }

    if ([json[@"code"] intValue] == 0) {
        // 请求成功
        NSArray *adsArr = json[@"ads"];
        
        if (adsArr.count == 0) {
            NSError * noAdDataError = [NSError networkResponseContainedNoData];
            [self didFailWithError:noAdDataError];
            return;
        }
        
        // 取出有效的广告配置数组
        NSMutableArray<MobiConfig *> * configurations = [NSMutableArray arrayWithCapacity:adsArr.count];
        for (NSDictionary *dict in adsArr) {
            MobiConfig *config = [[MobiConfig alloc] initWithAdConfigResponse:dict];
            if (config != nil) {
                [configurations addObject:config];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate communicatorDidReceiveAdConfigurations:configurations];
        });
        
    } else {
        NSLog(@"ad config request error = %@", json[@"msg"]);
        NSError * noResponsesError = [NSError adResponsesNotFound];
        [self didFailWithError:noResponsesError];
    }
    
}

// MARK: - Private
- (void)removeAllMoPubCookies {
    // Make NSURL from base URL
    NSURL *moPubBaseURL = [NSURL URLWithString:[MobiAPIEndpoints baseURL]];

    // Get array of cookies with the base URL, and delete each one
    NSArray <NSHTTPCookie *> * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:moPubBaseURL];
    for (NSHTTPCookie * cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

#pragma mark - Internal

- (NSError *)errorForStatusCode:(NSInteger)statusCode
{
    NSString *errorMessage = [NSString stringWithFormat:
                              NSLocalizedString(@"MoPub returned status code %d.",
                                                @"Status code error"),
                              statusCode];
    NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:errorMessage
                                                          forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"mopub.com" code:statusCode userInfo:errorInfo];
}

@end

