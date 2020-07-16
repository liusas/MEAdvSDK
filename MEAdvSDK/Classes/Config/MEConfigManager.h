//
//  MEConfigManager.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import <Foundation/Foundation.h>
#import "MEAdvConfig.h"
#import "MEConfigBaseClass.h"

/// 初始化完成的block
typedef void(^ConfigManangerFinished)(void);

@interface MEConfigManager : NSObject
/// 聚合平台appid,平台会为用户分配appid
/// 可在调用requestPlatformConfigWithUrl时传入,或直接赋值,但要早于调用requestPlatformConfigWithUrl
@property (nonatomic, copy) NSString *platformAppid;
/// 是否正在请求
@property (nonatomic, readonly) BOOL configIsRequesting;
/// 广告请求URL
@property (nonatomic, copy) NSString *adReuqestUrl;
/// 请求 填充 展现 点击的日志上报URL
@property (nonatomic, copy) NSString *adLogUrl;
/// 其他事件上报URL
@property (nonatomic, copy) NSString *developerUrl;
/// 广告请求的超时时长
@property (nonatomic, assign) NSTimeInterval adRequestTimeout;

/// 设备id
@property (nonatomic, copy) NSString *deviceId;

/// 广告平台配置信息字典,已删减排序
@property (nonatomic, strong) NSMutableDictionary *configDic;

/// 判断广告平台是否已经初始化
@property (nonatomic, assign) BOOL isInit;

+ (instancetype)sharedInstance;

/// 从服务端请求平台配置信息
+ (void)loadWithAppID:(NSString *)appid finished:(ConfigManangerFinished)finished;

/// 若上次广告展示失败,则根据广告场景id(sceneId)分配下一个广告平台展示广告,若没有符合条件则返回MEAdAgentTypeNone
/// @param sceneId 广告场景id
/// @param agentType 当前展示失败的广告平台
- (MEAdAgentType)nextAdPlatformWithSceneId:(NSString *)sceneId currentPlatform:(MEAdAgentType)agentType;

/// 获取该sceneId下的sortType是多少
- (NSInteger)getSortTypeFromSceneId:(NSString *)sceneId;

// MARK: - other
/// 场景id转为穿山甲posid,用于广告缓存
/// @param sceneId sceneId
- (NSString *)sceneIdExchangedBuadPosid:(NSString *)sceneId;

/// 获取顶层VC
- (UIViewController *)topVC;
@end
