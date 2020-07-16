//
//  AssignStrategy.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy.h"

@implementation StrategyResultModel
@end

@implementation AssignStrategy

- (NSArray <StrategyResultModel *>*)getExecuteAdapterModelsWithlistInfo:(MEConfigList *)listInfo
                                                                sceneId:(NSString *)sceneId
                                                           platformType:(MEAdAgentType)platformType {
    return nil;
}

/// 当指定了加载广告的平台时,统一调这个方法
- (NSArray <StrategyResultModel *>*)getExecuteAdapterModelsWithTargetPlatformType:(MEAdAgentType)platformType
                                                                         listInfo:(MEConfigList *)listInfo
                                                                          sceneId:(NSString *)sceneId {
    if (![listInfo.posid isEqualToString:sceneId]) {
        return nil;
    }
    
    if (platformType > MEAdAgentTypeNone && platformType < MEAdAgentTypeCount) {
        // 若指定了广告平台,则直接返回该平台的posid等信息
        StrategyResultModel *model = [StrategyResultModel new];
        for (int i = 0; i < listInfo.network.count; i++) {
            MEConfigNetwork *network = listInfo.network[i];
            if ([network.sdk isEqualToString:[MEAdNetworkManager getNetworkNameFromAgentType:platformType]]) {
                model.posid = network.parameter.posid;
                model.sceneId = sceneId;
                model.platformType = platformType;
                model.targetAdapterClass = [MEAdNetworkManager getAdapterClassFromAgentType:model.platformType];
                return @[model];
            }
        }
    }
    
    return nil;
}

@end
