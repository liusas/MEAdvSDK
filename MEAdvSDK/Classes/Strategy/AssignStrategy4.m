//
//  AssignStrategy4.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy4.h"
#import "StrategyFactory.h"

@implementation AssignStrategy4

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
    if ([StrategyFactory sharedInstance].sceneIdFrequencyDic[sceneId] && listInfo.sortParameter.count && platformType == MEAdAgentTypeAll && listInfo.sortType.intValue == 4) {
        
        NSString *platformStr = listInfo.sortParameter[[[StrategyFactory sharedInstance].sceneIdFrequencyDic[sceneId] intValue]];
        platformType = [MEAdNetworkManager getAgentTypeFromNetworkName:platformStr];
    }
    
    // 至此已经筛选出广告平台了,直接返回该平台的posid等信息
    return [self getExecuteAdapterModelsWithTargetPlatformType:platformType listInfo:listInfo sceneId:sceneId];;
}

@end
