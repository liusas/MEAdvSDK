//
//  MEAdNetworkManager.h
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/6/30.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"

NS_ASSUME_NONNULL_BEGIN

@class MEAdNetworkModel;

@interface MEAdNetworkManager : NSObject

/**< 各广告平台的别名,适配器类及平台可识别的平台类别枚举*/
@property (nonatomic, strong) NSMutableArray <MEAdNetworkModel *>*adNetworks;

// singleton
+ (instancetype)sharedInstance;

/// 根据下发的广告配置信息,配置个广告平台
/// @param infoArr 广告的配置数据模型数组
+ (void)configAdNetworksWithConfigInfo:(NSArray <MEConfigInfo *>*)infoArr;

/// 初始化各广告平台
+ (BOOL)launchAdNetwork;

/// 根据广告平台类型获取广告平台缩写
/// @param agentType 广告平台类型
+ (NSString *)getNetworkNameFromAgentType:(MEAdAgentType)agentType;

/// 根据广告平台类型获取对应的appid
/// @param agentType 广告平台类型
+ (NSString *)getAppidFromAgentType:(MEAdAgentType)agentType;

/// 根据广告名称缩写获取广告平台类型
/// @param sdk 广告平台的名称缩写
+ (MEAdAgentType)getAgentTypeFromNetworkName:(NSString *)sdk;

/// 根据广告平台类型获取对应的适配器
/// @param agentType 广告平台类型
+ (Class)getAdapterClassFromAgentType:(MEAdAgentType)agentType;

@end

@interface MEAdNetworkModel : NSObject

@property (nonatomic, copy) NSString *appid;/**< 各广告平台对应的appid*/
@property (nonatomic, copy) NSString *sdk;/**< tt,gdt,gdt2,admob,ks*/
@property (nonatomic, assign) MEAdAgentType agentType;/**< 广告平台类别*/
@property (nonatomic, assign) Class adapterClass;/**< 用于展示广告的适配器*/

@end

NS_ASSUME_NONNULL_END
