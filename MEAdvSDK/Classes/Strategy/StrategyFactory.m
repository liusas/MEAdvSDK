//
//  StrategyFactory.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "StrategyFactory.h"
#import "MEConfigManager.h"

@implementation StrategyFactory

+ (instancetype)sharedInstance {
    static StrategyFactory *factory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[StrategyFactory alloc] init];
    });
    return factory;
}

/// 根据场景id和服务端配置的order选择要加载的广告平台和sceneId
/// @param sceneId 场景id
- (NSArray <StrategyResultModel *>*)getPosidBySortTypeWithPlatform:(MEAdAgentType)platformType SceneId:(NSString *)sceneId {
    NSArray *arr = [self assignPosidSceneIdPlatform:platformType sceneId:sceneId defaultSceneId:nil];
    
    if (arr == nil) {
        return nil;
    }
    
    return arr;
}

/// 分配广告平台和posid,以及查询不到posid时的默认posid
- (NSArray <StrategyResultModel *>*)assignPosidSceneIdPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId defaultSceneId:(NSString *)defaultSceneId {
    
    if ([MEConfigManager sharedInstance].configDic == nil) {
        return nil;
    }
    
    // 先按场景找对应的广告位posid
    MEConfigList *listInfo = [MEConfigManager sharedInstance].configDic[sceneId];
    
    if (listInfo.sortType.intValue == 1) {
        // 按顺序
        id<AssignStrategy> assignStrategy = [[AssignStrategy1 alloc] init];
        return [assignStrategy getExecuteAdapterModelsWithlistInfo:listInfo sceneId:sceneId platformType:platformType];
    }
    
    if (listInfo.sortType.intValue == 4) {
        // 按指定顺序展示,控制频次
        id<AssignStrategy> assignStrategy = [[AssignStrategy4 alloc] init];
        return [assignStrategy getExecuteAdapterModelsWithlistInfo:listInfo sceneId:sceneId platformType:platformType];
    }
    
    if (listInfo.sortType.intValue == 5) {
        // 按顺序
        id<AssignStrategy> assignStrategy = [[AssignStrategy5 alloc] init];
        return [assignStrategy getExecuteAdapterModelsWithlistInfo:listInfo sceneId:sceneId platformType:platformType];
    }
    
    return nil;
}

/// 改变广告使用频次
/// @param sceneId 场景id
+ (void)changeAdFrequencyWithSceneId:(NSString *)sceneId {
    StrategyFactory *sharedInstance = StrategyFactory.sharedInstance;
    MEConfigList *listInfo = [MEConfigManager sharedInstance].configDic[sceneId];
    if (sharedInstance.sceneIdFrequencyDic[sceneId] && listInfo.sortParameter.count) {
        // 若场景id存在,则赋值
        sharedInstance.sceneIdFrequencyDic[sceneId] = @(([sharedInstance.sceneIdFrequencyDic[sceneId] intValue]+1) % listInfo.sortParameter.count);
    }
}

// MARK: - Getter
- (NSMutableDictionary *)sceneIdFrequencyDic {
    if (!_sceneIdFrequencyDic) {
        _sceneIdFrequencyDic = [NSMutableDictionary dictionary];
    }
    return _sceneIdFrequencyDic;
}

@end
