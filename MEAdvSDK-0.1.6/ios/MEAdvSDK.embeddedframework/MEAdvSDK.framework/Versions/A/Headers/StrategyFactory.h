//
//  StrategyFactory.h
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssignStrategy1.h"
#import "AssignStrategy4.h"
#import "AssignStrategy5.h"

NS_ASSUME_NONNULL_BEGIN

@interface StrategyFactory : NSObject

/// 广告展示频率的字典, sceneId:展示的posid数组下标
@property (nonatomic, strong) NSMutableDictionary *sceneIdFrequencyDic;

+ (instancetype)sharedInstance;

/// 根据服务端配置的策略选择执行展示广告的平台
/// @param sceneId 场景id
- (NSArray <StrategyResultModel *>*)getPosidBySortTypeWithPlatform:(MEAdAgentType)platformType SceneId:(NSString *)sceneId;

/// 更新广告频次,可在广告配置中配置展示顺序,平台在分配广告时优先按这个顺序分配广告平台
/// @param sceneId 场景id
+ (void)changeAdFrequencyWithSceneId:(NSString *)sceneId;

@end

NS_ASSUME_NONNULL_END
