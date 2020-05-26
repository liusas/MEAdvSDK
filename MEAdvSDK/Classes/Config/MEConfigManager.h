//
//  MEConfigManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import <Foundation/Foundation.h>
#import "MEAdvConfig.h"
#import "MEConfigBaseModel.h"
#import "MEAdFeedModel.h"

@class MEBaseAdapter;

/// 广告平台
typedef NS_ENUM(NSUInteger, MEAdAgentType) {
    MEAdAgentTypeAll,   // 所有可用的平台
    MEAdAgentTypeNone = 0,
    MEAdAgentTypeGDT,   // 广点通
    MEAdAgentTypeBUAD,  // 穿山甲
    MEAdAgentTypeAdmob,  // 谷歌
    MEAdAgentTypeKS,  // 快手
    MEAdAgentTypeCount,
};

/// 广告类型
typedef NS_ENUM(NSUInteger, MEAdType) {
    MEAdType_Feed = 1,      // 普通信息流
    MEAdType_Render_Feed,   // 自渲染信息流
    MEAdType_Interstitial,  // 插屏
    MEAdType_RewardVideo,   // 激励视频
    MEAdType_Splash,        // 开屏广告
};

@interface MEConfigManager : NSObject
/// 穿山甲Appid
@property (nonatomic, copy) NSString *BUADAPPId;
/// 广点通Appid
@property (nonatomic, copy) NSString *GDTAPPId;
/// 快手Appid
@property (nonatomic, copy) NSString *KSAppId;

@property (nonatomic, readonly) NSUInteger requestInterval;
/// 是否正在请求
@property (nonatomic, readonly) BOOL configIsRequesting;
/// 广告请求URL
@property (nonatomic, copy) NSString *adReuqestUrl;
/// 日志上报URL
@property (nonatomic, copy) NSString *adLogUrl;
@property (nonatomic, copy) NSString *deviceId;

/// 广告平台配置信息字典,已删减排序
@property (nonatomic, strong) NSMutableDictionary *configDic;
/// 广告平台对应的自家服务端代号,穿山甲:tt,广点通:gdt,谷歌:admob,快手:ks
@property (nonatomic, strong) NSDictionary *dicPlatformTypeName;

/// 判断广告平台是否已经初始化
@property (nonatomic, assign, readonly) BOOL isInit;

+ (instancetype)sharedInstance;

// 根据广告平台类型获取相应的适配器
+ (MEBaseAdapter *)getAdapterOfADPlatform:(MEAdAgentType)platformType;
/// 根据广告平台和广告类型分配相应适配器
+ (MEBaseAdapter *)getAdapterByPlatform:(MEAdAgentType)platformType andAdType:(MEAdType)adType;

/// 从服务端请求各平台配置
- (void)platformConfigIfRequestWithUrl:(NSString *)adRequestUrl;

/// 若上次广告展示失败,则根据广告场景id(sceneId)分配下一个广告平台展示广告,若没有符合条件则返回MEAdAgentTypeNone
/// @param sceneId 广告场景id
/// @param agentType 当前展示失败的广告平台
- (MEAdAgentType)nextAdPlatformWithSceneId:(NSString *)sceneId currentPlatform:(MEAdAgentType)agentType;

// MARK: - 按广告位posid选择广告的逻辑,此次采用
/// 根据广告场景id(sceneId)和指定广告平台分配相应广告适配器处理信息流广告展示,
/// 返回数组[该广告平台对应的posid, 广告场景sceneId, 广告平台platform]
/// @param platformType 指定广告平台,若platformType为MEAdAgentTypeNone,则按广告配置的优先级及频率等规则分配
/// @param sceneId 场景id
- (NSArray *)getFeedPosidByOrderWithPlatform:(MEAdAgentType)platformType SceneId:(NSString *)sceneId;

/// 根据广告场景id(sceneId)和指定广告平台分配相应广告适配器处理激励视频广告展示,
/// 返回数组[该广告平台对应的posid, 广告场景sceneId, 广告平台platform]
/// @param platformType 指定广告平台,若platformType为MEAdAgentTypeNone,则按广告配置的优先级及频率等规则分配
/// @param sceneId 场景id
- (NSArray *)getRewardVideoPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId;

/// 根据广告场景id(sceneId)和指定广告平台分配相应广告适配器处理开屏广告展示,
/// 返回数组[该广告平台对应的posid, 广告场景sceneId, 广告平台platform]
/// @param platformType 指定广告平台,若platformType为MEAdAgentTypeNone,则按广告配置的优先级及频率等规则分配
/// @param sceneId 场景id
- (NSArray *)getSplashPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId;

/// 根据广告场景id(sceneId)和指定广告平台分配相应广告适配器处理插屏广告展示,
/// 返回数组[该广告平台对应的posid, 广告场景sceneId, 广告平台platform]
/// @param platformType 指定广告平台,若platformType为MEAdAgentTypeNone,则按广告配置的优先级及频率等规则分配
/// @param sceneId 场景id
- (NSArray *)getInterstitialPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId;

// MARK: - other
/// 更新广告频次,可在广告配置中配置展示顺序,平台在分配广告时优先按这个顺序分配广告平台
/// @param sceneId 场景id
- (void)changeAdFrequencyWithSceneId:(NSString *)sceneId;

/// 场景id转为穿山甲posid,用于广告缓存
/// @param sceneId sceneId
- (NSString *)sceneIdExchangedBuadPosid:(NSString *)sceneId;

/// 获取顶层VC
- (UIViewController *)topVC;
@end
