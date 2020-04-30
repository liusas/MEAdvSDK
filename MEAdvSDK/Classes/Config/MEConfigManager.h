//
//  MEConfigManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import <Foundation/Foundation.h>
#import "MEConfigBaseModel.h"
#import "MEAdFeedModel.h"

@class MEBaseAdapter;

#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#define kScreenWidth [[UIApplication sharedApplication]keyWindow].bounds.size.width
#define kScreenHeight [[UIApplication sharedApplication]keyWindow].bounds.size.height

#define kRequestConfigNotify @"kRequestConfigNotify"

#define FilePath_AllConfig  [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"MEAdvertiseAllConfig.plist"]

#define kConfigiOSSign @"2048" // 广告配置信息iOS对应的前缀

#define kDefaultSplashPosid @"2048025" // 服务端默认的开屏广告id
#define kDefaultRewardVideoPosid @"2048020" //服务端默认激励视频广告位Id
#define kDefaultFeedPosid @"2048018" //服务端默认信息流广告位Id
#define kDefaultInterstitialPosid @"2048043" //服务端默认插屏广告位Id
#define kDefaultRenderFeedPosid @"2048051" // 自渲染信息流广告位id

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

// 根据广告平台类型查询广告平台名称
- (NSString *)platformNameOf:(MEAdAgentType)platformType;


/// 从服务端请求各平台配置
- (void)platformConfigIfRequestWithUrl:(NSString *)adRequestUrl;

/// 若此次广告展示失败,返回备用展示的广告平台,没有则返回none
/// @param sceneId 场景id
/// @param agentType 当前展示失败的广告平台
- (MEAdAgentType)nextAdPlatformWithSceneId:(NSString *)sceneId currentPlatform:(MEAdAgentType)agentType;

// MARK: - 按广告位posid选择广告的逻辑,此次采用
/// 根据场景id和服务端配置的order选择要加载的广告平台和sceneId
/// @param sceneId 场景id
- (NSArray *)getFeedPosidByOrderWithPlatform:(MEAdAgentType)platformType SceneId:(NSString *)sceneId;

/// 根据广告平台获取激励视频的posid
/// @param platformType 广告平台
- (NSArray *)getRewardVideoPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId;

/// 开屏广告
- (NSArray *)getSplashPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId;

/// 插屏广告
- (NSArray *)getInterstitialPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId;

// MARK: - other
/// 改变广告使用频次
/// @param sceneId 场景id
- (void)changeAdFrequencyWithSceneId:(NSString *)sceneId;

/// 场景id转为穿山甲posid,用于广告缓存
/// @param sceneId sceneId
- (NSString *)sceneIdExchangedBuadPosid:(NSString *)sceneId;

/// 获取顶层VC
- (UIViewController *)topVC;
@end
