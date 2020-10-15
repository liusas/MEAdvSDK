//
//  MEMobipubAdapter.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/10/12.
//

#import "MEMobipubAdapter.h"

// Initialization configuration keys
static NSString * const kMobiPubAppID = @"appid";

// Errors
static NSString * const kAdapterErrorDomain = @"com.mobipub.mobipub-ios-sdk.mobipub-buad-adapter";

typedef NS_ENUM(NSInteger, MobiPubAdapterErrorCode) {
    MobiPubAdapterErrorCodeMissingAppId,
};

@implementation MEMobipubAdapter

#pragma mark - Caching

+ (void)updateInitializationParameters:(NSDictionary *)parameters {
    // These should correspond to the required parameters checked in
    // `initializeNetworkWithConfiguration:complete:`
    NSString * appId = parameters[kMobiPubAppID];
    
    if (appId != nil) {
        NSDictionary * configuration = @{ kMobiPubAppID: appId };
        [MEMobipubAdapter setCachedInitializationParameters:configuration];
    }
}

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    return @"1.0.9";
}

- (NSString *)biddingToken {
    return nil;
}

- (NSString *)mobiNetworkName {
    return @"tt";
}

- (NSString *)networkSdkVersion {
    return @"3.2.6.2";
}

#pragma mark - MobiPub ad type
- (Class)getSplashCustomEvent {
    return NSClassFromString(@"MobiPrivateSplashCustomEvent");
}

- (Class)getBannerCustomEvent {
    return NSClassFromString(@"MobiPrivateBannerCustomEvent");
}

- (Class)getFeedCustomEvent {
    return NSClassFromString(@"MobiPrivateFeedCustomEvent");
}

- (Class)getInterstitialCustomEvent {
    return NSClassFromString(@"MobiPrivateInterstitialCustomEvent");
}

- (Class)getRewardedVideoCustomEvent {
    return NSClassFromString(@"MobiPrivateRewardedVideoCustomEvent");
}

- (Class)getFullscreenCustomEvent {
    return NSClassFromString(@"MobiPrivateFullScreenVideoCustomEvent");
}

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *,id> *)configuration complete:(void (^)(NSError * _Nullable))complete {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *appid = configuration[kMobiPubAppID];
            
            if (complete != nil) {
                complete(nil);
            }
        });
    });
}

// MoPub collects GDPR consent on behalf of Google
+ (NSString *)npaString
{
//    return !MobiPub.sharedInstance.canCollectPersonalInfo ? @"1" : @"";
    return @"";
}

/// 获取顶层VC
+ (UIViewController *)topVC {
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    if (![[UIApplication sharedApplication].windows containsObject:rootWindow]
        && [UIApplication sharedApplication].windows.count > 0) {
        rootWindow = [UIApplication sharedApplication].windows[0];
    }
    UIViewController *topVC = rootWindow.rootViewController;
    // 未读到keyWindow的rootViewController，则读UIApplicationDelegate的window，但该window不一定存在
    if (nil == topVC && [[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        topVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

@end
