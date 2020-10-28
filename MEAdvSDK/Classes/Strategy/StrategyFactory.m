//
//  StrategyFactory.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "StrategyFactory.h"
#import "MobiGlobalConfig.h"
#import "MobiGlobalConfigServer.h"

@implementation StrategyFactory

+ (instancetype)sharedInstance {
    static StrategyFactory *factory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[StrategyFactory alloc] init];
    });
    return factory;
}

/// 根据 sceneId 和广告类型获取允许展示的广告平台
/// @param sceneId 场景id
- (NSArray <MobiConfig *>*)getConfigurationsWithAdType:(MobiAdType)adType sceneId:(NSString *)sceneId {
    
    if (adType == MobiAdTypeUnknown) {
        return nil;
    }
    
    return [self assignConfigurationsWithAdType:adType sceneId:sceneId];
}

- (NSArray <MobiConfig *>*)assignConfigurationsWithAdType:(MobiAdType)adType sceneId:(NSString *)sceneId {
    if ([MobiGlobalConfig sharedInstance].configDic == nil) {
        return nil;
    }
    
    // 先按场景找对应的广告位posid
    MEConfigList *listInfo = [MobiGlobalConfig sharedInstance].configDic[sceneId];
    
    id<AssignStrategy> assignStrategy = nil;
    if (listInfo.sortType.intValue == 1) {
        // 按顺序
        assignStrategy = [[AssignStrategy1 alloc] init];
        
    }
    
    if (listInfo.sortType.intValue == 4) {
        // 按指定顺序展示,控制频次
        assignStrategy = [[AssignStrategy4 alloc] init];
    }
    
    if (listInfo.sortType.intValue == 5) {
        // 并行
        assignStrategy = [[AssignStrategy5 alloc] init];
    }
    
    return [assignStrategy getExecuteConfigurationWithListInfo:listInfo sceneId:sceneId adType:adType];
}

/// 改变广告使用频次
/// @param sceneId 场景id
+ (void)changeAdFrequencyWithSceneId:(NSString *)sceneId {
    StrategyFactory *sharedInstance = StrategyFactory.sharedInstance;
    MEConfigList *listInfo = [MobiGlobalConfig sharedInstance].configDic[sceneId];
    if (sharedInstance.sceneIdFrequencyDic[sceneId] && listInfo.orderParameter.count) {
        // 若场景id存在,则赋值
        sharedInstance.sceneIdFrequencyDic[sceneId] = @(([sharedInstance.sceneIdFrequencyDic[sceneId] intValue]+1) % listInfo.orderParameter.count);
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
