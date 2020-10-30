//
//  AssignStrategy.h
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobiGlobalConfig.h"
#import "MEAdNetworkManager.h"
#import "MobiConfig.h"
#import "MobiAdapterConfiguration.h"

@interface StrategyResultModel : NSObject

@property (nonatomic, copy) NSString *posid;
@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, assign) MEAdAgentType platformType;
@property (nonatomic, assign) Class targetAdapterClass;

@end

@protocol AssignStrategy <NSObject>

- (NSArray <MobiConfig *>*)getExecuteConfigurationWithListInfo:(MEConfigList *)listInfo sceneId:(NSString *)sceneId adType:(MobiAdType)adType;

@end

@interface AssignStrategy : NSObject<AssignStrategy>


- (Class)getClassByAdType:(MobiAdType)adType adapterProvider:(id<MobiAdapterConfiguration>)adapterProvider;

/// 当上层指定了加载广告的平台时,统一调这个方法
- (NSArray <StrategyResultModel *>*)getExecuteAdapterModelsWithTargetPlatformType:(MEAdAgentType)platformType
                                                                         listInfo:(MEConfigList *)listInfo
                                                                          sceneId:(NSString *)sceneId;

@end
