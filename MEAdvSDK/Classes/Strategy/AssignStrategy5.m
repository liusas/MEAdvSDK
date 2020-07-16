//
//  AssignStrategy5.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy5.h"

@implementation AssignStrategy5

- (NSArray<StrategyResultModel *> *)getExecuteAdapterModelsWithlistInfo:(MEConfigList *)listInfo
                                                                      sceneId:(NSString *)sceneId
                                                                 platformType:(MEAdAgentType)platformType {
    if (![listInfo.posid isEqualToString:sceneId]) {
        return nil;
    }
    
    // 若指定了广告平台,则直接返回该平台的posid等信息
    if (platformType > MEAdAgentTypeNone && platformType < MEAdAgentTypeCount) {
        return [self getExecuteAdapterModelsWithTargetPlatformType:platformType listInfo:listInfo sceneId:sceneId];
    }
    
    // 先看该广告位是否需要控制频次
    if (platformType == MEAdAgentTypeAll && listInfo.sortType.intValue == 5) {
        NSMutableArray *resultArr = [NSMutableArray array];
        // 遍历sceneId下的所有广告平台,这些广告平台需要同时加载
        for (int i = 0; i < listInfo.network.count; i++) {
            MEConfigNetwork *network = listInfo.network[i];
            StrategyResultModel *model = [StrategyResultModel new];
            
            model.posid = network.parameter.posid;
            model.sceneId = sceneId;
            model.platformType = [MEAdNetworkManager getAgentTypeFromNetworkName:network.sdk];
            model.targetAdapterClass = [MEAdNetworkManager getAdapterClassFromAgentType:model.platformType];
            [resultArr addObject:model];
        }
        return resultArr;
    }
    
    return nil;
}

@end
