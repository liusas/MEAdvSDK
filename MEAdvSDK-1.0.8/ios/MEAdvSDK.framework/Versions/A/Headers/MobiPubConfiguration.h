//
//  MobiPubConfiguration.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/29.
//

#import <Foundation/Foundation.h>
#import "MPBLogLevel.h"
#import "MobiAdapterConfiguration.h"
#import "MPMediationSettingsProtocol.h"
#import "MEConfigInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobiPubConfiguration : NSObject

@property (nonatomic, strong, nullable) NSArray<Class<MobiAdapterConfiguration>> * additionalNetworks;

/**
 This API can be used if you want to support other networks. Default value is nil.
 */
@property (nonatomic, strong, nullable) NSArray <MEConfigInfo *>*additionalInfoArr;

/**
 广告平台分配给App的唯一标识
 */
@property (nonatomic, strong) NSString * appid;

/**
 This API can be used if you want to allow supported SDK networks to collect user information on the basis of legitimate interest. The default value is @c NO.
 */
@property (nonatomic, assign) BOOL allowLegitimateInterest;

/**
 广告SDK的log级别. 默认情况下为MobiLogLevelNone.
 */
@property (nonatomic, assign) MPBLogLevel loggingLevel;

/**
 Optional global configurations for all ad networks your app supports.
 */
@property (nonatomic, strong, nullable) NSArray<id<MPMediationSettingsProtocol>> * globalMediationSettings;

/**
 Optional configuration settings for mediated networks during initialization. To add entries
 to this dictionary, use the convenience method @c setNetworkConfiguration:forMediationAdapter:
 */
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> * mediatedNetworkConfigurations;

/**
 Optional MoPub request options for mediated networks. To add entries
 to this dictionary, use the convenience method @c setmobiPubRequestOptions:forMediationAdapter:
 */
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> * mobiPubRequestOptions;

/**
 初始化广告的配置信息MobiPubConfiguration
 @param appid 广告平台分配给App的唯一标识
 @return 返回一个configuration实例
 */
- (instancetype)initWithAppIDForAppid:(NSString *)appid NS_DESIGNATED_INITIALIZER;


/**
 Sets the network configuration options for a given mediated network class name.
 @param configuration Configuration parameters specific to the network. Only @c NSString, @c NSNumber, @c NSArray, and @c NSDictionary types are allowed. This value may be @c nil.
 @param adapterClassName The class name of the mediated adapter that will receive the inputted configuration. The adapter class must implement the @c MobiAdapterConfiguration protocol.
 */
- (void)setNetworkConfiguration:(NSDictionary<NSString *, id> * _Nullable)configuration
            forMediationAdapter:(NSString *)adapterClassName;

/**
 Sets the mediated network's MoPub request options.
 @param options MoPub request options for the mediated network.
 @param adapterClassName The class name of the mediated adapter that will receive the inputted configuration. The adapter class must implement the @c MobiAdapterConfiguration protocol.
 */
- (void)setmobiPubRequestOptions:(NSDictionary<NSString *, NSString *> * _Nullable)options
           forMediationAdapter:(NSString *)adapterClassName;

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
