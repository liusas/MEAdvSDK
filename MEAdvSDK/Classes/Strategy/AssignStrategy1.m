//
//  AssignStrategy1.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy1.h"

@implementation AssignStrategy1

- (NSArray <StrategyResultModel *>*)getExecuteAdapterModelsWithlistInfo:(MEConfigList *)listInfo
                                                                      sceneId:(NSString *)sceneId
                                                                 platformType:(MEAdAgentType)platformType {
    if (![listInfo.posid isEqualToString:sceneId]) {
        return nil;
    }
    
    if (platformType > MEAdAgentTypeNone && platformType < MEAdAgentTypeCount) {
        // 若指定了广告平台,则直接返回该平台的posid等信息
        return [self getExecuteAdapterModelsWithTargetPlatformType:platformType listInfo:listInfo sceneId:sceneId];
    }
    
    // 按顺序选择优先级最高的,即第1个
    if (listInfo.network.count) {
        MEConfigNetwork *network = listInfo.network[0];
        platformType = [MEAdNetworkManager getAgentTypeFromNetworkName:network.sdk];
    }
    
    return [self getExecuteAdapterModelsWithTargetPlatformType:platformType listInfo:listInfo sceneId:sceneId];
}

@end
