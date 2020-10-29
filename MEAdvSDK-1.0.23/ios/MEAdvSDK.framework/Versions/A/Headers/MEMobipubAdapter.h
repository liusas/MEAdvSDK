//
//  MEMobipubAdapter.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/10/12.
//

#import "MobiBaseAdapterConfiguration.h"
#if __has_include(<MEAdvSDK/MobiPub.h>)
#import <MEAdvSDK/MobiPub.h>
#else
#import "MobiBaseAdapterConfiguration.h"
#import "MobiPub.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MEMobipubAdapter : MobiBaseAdapterConfiguration

// Caching
/**
 Extracts the parameters used for network SDK initialization and if all required
 parameters are present, updates the cache.
 @param parameters Ad response parameters
 */
+ (void)updateInitializationParameters:(NSDictionary *)parameters;

/// 获取顶层VC
+ (UIViewController *)topVC;

@end

NS_ASSUME_NONNULL_END
