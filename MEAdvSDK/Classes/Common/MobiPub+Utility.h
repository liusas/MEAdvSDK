//
//  MobiPub+Utility.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/10.
//

#import "MobiPub.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobiPub (Utility)

/**
 This is a simplified version of @c [MoPub openURL:options:completion:], which provides empty @c options
 dictionary and nil @c completion.

 @param url A URL (Universal Resource Locator).
 */
+ (void)openURL:(NSURL*)url;

/**
 This is a wrapper method that picks the correct version of @c [UIApplication  openURL:] (versus
 @c [UIApplication  openURL:options:completionHandler:]) base the iOS target.

 @param url A URL (Universal Resource Locator).
 @param options A dictionary of options to use when opening the URL.
 @param completion The block to execute with the results.
 */
+ (void)openURL:(NSURL*)url
        options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
     completion:(void (^ __nullable)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
