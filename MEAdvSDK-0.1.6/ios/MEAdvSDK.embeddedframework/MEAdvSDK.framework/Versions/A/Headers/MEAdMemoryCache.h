//
//  MEAdMemoryCache.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/12/12.
//

#import <Foundation/Foundation.h>
#import "MEConfigManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEAdMemoryCache : NSObject
/// 缓存个数限制
@property (readonly) NSUInteger totalCount;
/// 周期长度
@property NSTimeInterval ageLimit;
/// 修剪周期,单位毫秒
@property NSTimeInterval autoTrimInterval;

/// 判断缓存中是否存在key对应的广告数据
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (BOOL)containsObjectWithSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType;

/// 添加广告数据到缓存
/// @param object 广告数据,应该是一个view
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (void)setObject:(id)object forSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType;

/// 根据广告场景id查找缓存中的广告数据
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (nullable id)objectForSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType;

/// 删除场景id对应的广告数据
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (void)removeObjectForSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType;

/// 清空所有缓存
- (void)removeAllObject;

/// 根据周期修剪缓存,将过期广告删除,并拉取新广告
/// @param age 周期长度
- (void)trimToAge:(NSTimeInterval)age;
@end

NS_ASSUME_NONNULL_END
