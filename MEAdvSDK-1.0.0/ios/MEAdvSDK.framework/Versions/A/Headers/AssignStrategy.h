//
//  AssignStrategy.h
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"
#import "MEAdNetworkManager.h"

@interface StrategyResultModel : NSObject

@property (nonatomic, copy) NSString *posid;
@property (nonatomic, copy) NSString *sceneId;
@property (nonatomic, assign) MEAdAgentType platformType;
@property (nonatomic, assign) Class targetAdapterClass;

@end

@protocol AssignStrategy <NSObject>

- (NSArray <StrategyResultModel *>*)getExecuteAdapterModelsWithlistInfo:(MEConfigList *)listInfo
                                                                sceneId:(NSString *)sceneId
                                                           platformType:(MEAdAgentType)platformType;

@end

@interface AssignStrategy : NSObject<AssignStrategy>

/// 当上层指定了加载广告的平台时,统一调这个方法
- (NSArray <StrategyResultModel *>*)getExecuteAdapterModelsWithTargetPlatformType:(MEAdAgentType)platformType
                                                                         listInfo:(MEConfigList *)listInfo
                                                                          sceneId:(NSString *)sceneId;

@end
