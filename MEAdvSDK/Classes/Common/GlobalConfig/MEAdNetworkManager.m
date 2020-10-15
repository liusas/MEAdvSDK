//
//  MEAdNetworkManager.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/6/30.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "MEAdNetworkManager.h"
#import "MEConfigInfo.h"
#import "MobiAdapterConfiguration.h"
#import "NSBundle+MPAdditions.h"
#import "MPLogging.h"

static NSString * kAdaptersFile     = @"MobiAdapters";
static NSString * kAdaptersFileType = @"plist";

@implementation MEAdNetworkModel
@end

@interface MEAdNetworkManager ()

/**
 Dictionary of all instantiated adapter information providers.
 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<MobiAdapterConfiguration>> * adapters;

/**
 All certified adapter information classes that exist within the current runtime.
 */
@property (nonatomic, strong) NSDictionary<NSString *, Class<MobiAdapterConfiguration>> * certifiedAdapterClasses;

/**
 Initialization queue.
 */
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation MEAdNetworkManager

+ (instancetype)sharedInstance {
    static MEAdNetworkManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [MEAdNetworkManager new];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _initializedAdapters = [NSMutableDictionary dictionary];
        // The adapterClasses is NSSet,contains `sdk` and `className`
        _certifiedAdapterClasses = MEAdNetworkManager.certifiedAdapterInformationProviderClasses;
        // 初始化一个串行队列,用来初始化广告适配器
        _queue = dispatch_queue_create("Mediated Adapter Initialization Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (void)configAdNetworksWithConfigInfo:(NSArray <MEConfigInfo *>*)infoArr {
    MEAdNetworkManager *sharedInstance = [MEAdNetworkManager sharedInstance];
    
    for (int i = 0; i < infoArr.count; i++) {
        MEConfigInfo *info = infoArr[i];
        if (sharedInstance.certifiedAdapterClasses[info.sdk] != nil) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.adapterClass = sharedInstance.certifiedAdapterClasses[info.sdk];
            [sharedInstance.adNetworks addObject:model];
        }
    }
}

/// 初始化各广告平台
+ (BOOL)launchAdNetwork {
    // 从配置中取出广告平台模型,用适配器进行相应的初始化
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        id<MobiAdapterConfiguration> adapterProvider = (id<MobiAdapterConfiguration>)[[[model.adapterClass class] alloc] init];
        if (model.appid == nil) {
            MPLogInfo(@"error: appid can not be nil");
            continue;
        }
        
        NSMutableDictionary *initialParams = [NSMutableDictionary dictionaryWithCapacity:1];
        initialParams[@"appid"] = model.appid;
        initialParams[@"sdk"] = model.sdk;
        
        [adapterProvider initializeNetworkWithConfiguration:initialParams complete:^(NSError * _Nullable error) {
            if (error != nil) {
                NSString * logPrefix = [NSString stringWithFormat:@"Adapter %@ encountered an error during initialization", NSStringFromClass(model.adapterClass)];
                MPLogEvent([MPLogEvent error:error message:logPrefix]);
            }
        }];
        
        MEAdNetworkManager.sharedInstance.initializedAdapters[model.sdk] = adapterProvider;
    }
    
    return YES;
}

/// 根据广告平台类型获取广告平台缩写
/// @param agentType 广告平台类型
+ (NSString *)getNetworkNameFromAgentType:(MEAdAgentType)agentType {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.agentType == agentType) {
            return model.sdk;
        }
    }
    
    return nil;
}

/// 根据广告平台类型获取对应的appid
/// @param agentType 广告平台类型
+ (NSString *)getAppidFromAgentType:(MEAdAgentType)agentType {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.agentType == agentType) {
            return model.appid;
        }
    }
    
    return nil;
}

/// 根据广告名称缩写获取广告平台类型
/// @param sdk 广告平台的名称缩写
+ (MEAdAgentType)getAgentTypeFromNetworkName:(NSString *)sdk {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.sdk == sdk) {
            return model.agentType;
        }
    }
    
    return MEAdAgentTypeNone;
}

/// 根据广告平台类型获取对应的适配器
/// @param agentType 广告平台类型
+ (Class)getAdapterClassFromAgentType:(MEAdAgentType)agentType {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.agentType == agentType) {
            return model.adapterClass;
        }
    }
    
    return Nil;
}

#pragma mark - Certified Adapter Information Providers

/**
 Attempts to retrieve @c MPAdapters.plist from the current bundle's resources.
 @return The file path if available; otherwise @c nil.
 */
+ (NSString *)adapterInformationProvidersFilePath {
    // Retrieve the plist containing the default adapter information provider class names.
    NSBundle * parentBundle = [NSBundle resourceBundleForClass:self.class];
    NSString * filepath = [parentBundle pathForResource:kAdaptersFile ofType:kAdaptersFileType];
    return filepath;
}

/**
 Retrieves the certified adapter information classes that exist within the
 current runtime.
 @return List of certified adapter information classes that exist in the runtime.
 */
+ (NSDictionary<NSString *, Class<MobiAdapterConfiguration>> * _Nonnull)certifiedAdapterInformationProviderClasses {
    // Certified adapters file not present. Do not continue.
    NSString * filepath = MEAdNetworkManager.adapterInformationProvidersFilePath;
    if (filepath == nil) {
        MPLogInfo(@"Could not find MobiAdapters.plist.");
        return [NSDictionary dictionary];
    }

    // Try to retrieve the class for each certified adapter
    NSDictionary * adapterClassNameDic = [NSDictionary dictionaryWithContentsOfFile:filepath];
    
    NSMutableDictionary *adapters = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < adapterClassNameDic.allKeys.count; i++) {
        NSString *networkAdapterName = adapterClassNameDic.allValues[i];
        Class adapterClass = NSClassFromString(networkAdapterName);
        if (adapterClass != Nil && [adapterClass conformsToProtocol:@protocol(MobiAdapterConfiguration)]) {
            adapters[adapterClassNameDic.allKeys[i]] = adapterClass;
        }
    }

    return adapters;
}

// MARK: - Getter
- (NSMutableArray<MEAdNetworkModel *> *)adNetworks {
    if (!_adNetworks) {
        _adNetworks = [NSMutableArray array];
    }
    return _adNetworks;
}

@end
