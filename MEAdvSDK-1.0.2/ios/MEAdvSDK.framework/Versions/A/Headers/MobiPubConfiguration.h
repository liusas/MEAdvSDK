//
//  MobiPubConfiguration.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/29.
//

#import <Foundation/Foundation.h>
#import "MobiLogLevel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobiPubConfiguration : NSObject

/**
 广告平台分配给App的唯一标识
 */
@property (nonatomic, strong) NSString * appidForAppInitialization;

/**
 广告SDK的log级别. 默认情况下为MobiLogLevelNone.
 */
@property (nonatomic, assign) MobiLogLevel loggingLevel;

/**
 初始化广告的配置信息MobiPubConfiguration
 @param appid 广告平台分配给App的唯一标识
 @return 返回一个configuration实例
 */
- (instancetype)initWithAppIDForAppInitialization:(NSString *)appid NS_DESIGNATED_INITIALIZER;

/**
 不允许使用init初始化,用`initWithAppIDForAppInitialization`代替
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 不允许使用new初始化,用`initWithAppIDForAppInitialization`代替
 */
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
