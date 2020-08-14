//
//  MobiPub+Utility.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/10.
//

#import "MobiPub+Utility.h"

@implementation MobiPub (Utility)

+ (void)openURL:(NSURL*)url {
    [self openURL:url options:@{} completion:nil];
}

+ (void)openURL:(NSURL*)url
        options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
     completion:(void (^ __nullable)(BOOL success))completion {
    if (@available(iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:url options:options completionHandler:completion];
    } else {
        completion([[UIApplication sharedApplication] openURL:url]);
    }
}

@end
