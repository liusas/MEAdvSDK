//
//  MEConfigManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import "MEConfigManager.h"
#import "MEBUADAdapter.h"
#import "MEGDTAdapter.h"
#import "MEAdombAdapter.h"
#import "MEKSAdapter.h"
#import "MEGDTFeedRenderAdapter.h"
#import "NBLHTTPManager.h"
#import "MEAdBaseManager.h"
#import <AdSupport/AdSupport.h>
#import "MEAdLogModel.h"

@interface MEConfigManager ()

@property (nonatomic, strong) NSDictionary *dicBUADConfig;  /// 穿山甲的配置参数
@property (nonatomic, strong) NSDictionary *dicGDTConfig;   /// 广点通的配置参数

@property (nonatomic, assign) NSTimeInterval timeConfig; /// 获取配置的时间
@property (nonatomic, assign) NSTimeInterval timeOut; /// 配置过期时长

@property (nonatomic, copy) NSArray *sdkInfoArr; /// 配置的广告平台,用于初始化
/// 广告展示频率的字典, sceneId:展示的posid数组下标
@property (nonatomic, strong) NSMutableDictionary *sceneIdFrequencyDic;
/// 判断广告平台是否已经初始化
@property (nonatomic, assign) BOOL isInit;
/// 各广告位的默认posid
@property (nonatomic, copy) NSDictionary *defaultPosidDict;

@end

@implementation MEConfigManager

+ (void)load {
//    [[MEConfigManager sharedInstance] notifAppDidBecomeActive:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _configIsRequesting = NO;
        // 监听app激活通知
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifAppWillEnterForegroundActive:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        // 平台类型与平台名称对应表
        self.dicPlatformTypeName = @{@(MEAdAgentTypeBUAD): @"tt",
                                     @(MEAdAgentTypeGDT): @"gdt",
                                     @(MEAdAgentTypeAdmob): @"admob",
                                     @(MEAdAgentTypeKS): @"ks"
        };
        
        // 默认广告位id,在为请求下来广告配置时使用
//        self.defaultPosidDict = @{kDefaultFeedPosid : @{@"tt" : @"938537751",
//                                                        @"gdt" : @"2040198235337269"},
//                                  kDefaultRewardVideoPosid: @{@"tt" : @"938537726",
//                                                              @"gdt" : @"7020493480243376"},
//                                  kDefaultInterstitialPosid: @{@"tt" : @"941395451",
//                                                               @"gdt" : @"2040098421312295"},
//                                  kDefaultSplashPosid: @{@"tt" : @"838537172",
//                                                         @"gdt" : @"1070390225538460"}};
    }
    return self;
}


// MARK: - Notification

/// 监听app变成活跃状态
- (void)notifAppDidBecomeActive:(NSNotification *)notif {
    // 根据服务器返回过期时长, 判断多久更新一次配置
    if (!self.configIsRequesting &&
        [NSDate date].timeIntervalSince1970 - self.timeConfig > self.timeOut) {
        [self platformConfigIfRequestWithUrl:self.adReuqestUrl];
    } else {
        // 读缓存配置
        // 若当前内存中已存在配置信息,则不读取文件
        if (self.configDic) {
            return;
        }
        
        [self getConfigFromFile];
    }
}

/// 监听app即将进入前台,检测广告日志并上传
- (void)notifAppWillEnterForegroundActive: (NSNotification *)notify {
    // 检测若广告日志超过20条,则上传
    [MEAdLogModel checkLogsAndUploadToServer];
}

/// 从文件中读取广告配置
- (void)getConfigFromFile {
//    self.configDic = [NSMutableDictionary dictionaryWithContentsOfFile:FilePath_AllConfig];
    
    NSDictionary *responseObject = [NSMutableDictionary dictionaryWithContentsOfFile:FilePath_AllConfig];
    
    if (responseObject == nil) {
    } else {
        [self dispatchConfigDicWithResponseObj:responseObject];
    }
    
    if (self.configDic == nil) {
//        self.BUADAPPId = @"5038537";
//        self.GDTAPPId = @"1110066776";
//        self.KSAppId = @"510400002";
        [self initPlatform];
        return;
    }
    self.sdkInfoArr = self.configDic[@"sdkInfo"];
    [self parsePlatformPriority];
}

// MARK: - Public

+ (instancetype)sharedInstance {
    static MEConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MEConfigManager alloc] init];
    });
    return sharedInstance;
}

// 根据广告平台类型获取相应的适配器
+ (MEBaseAdapter *)getAdapterOfADPlatform:(MEAdAgentType)platformType {
    MEBaseAdapter *adapter = nil;
    switch (platformType) {
        case MEAdAgentTypeBUAD:
            adapter = [MEBUADAdapter sharedInstance];
            break;
        case MEAdAgentTypeGDT:
            adapter = [MEGDTAdapter sharedInstance];
            break;
        case MEAdAgentTypeAdmob:
            adapter = [MEAdombAdapter sharedInstance];
            break;
        case MEAdAgentTypeKS:
            adapter = [MEKSAdapter sharedInstance];
            break;
        default:
            break;
    }
    return adapter;
}

/// 根据广告平台和广告类型分配相应适配器
+ (MEBaseAdapter *)getAdapterByPlatform:(MEAdAgentType)platformType andAdType:(MEAdType)adType {
    MEBaseAdapter *adapter = nil;
    switch (platformType) {
        case MEAdAgentTypeBUAD: {
            if (adType == MEAdType_Render_Feed) {
                // 穿山甲暂时没有自渲染信息流,暂留
                adapter = [MEGDTFeedRenderAdapter sharedInstance];
            } else {
                adapter = [MEBUADAdapter sharedInstance];
            }
        }
            break;
        case MEAdAgentTypeGDT: {
            if (adType == MEAdType_Render_Feed) {
//                adapter = [[MEGDTFeedRenderAdapter alloc] init];
                adapter = [MEGDTFeedRenderAdapter sharedInstance];
            } else {
//                adapter = [[MEGDTAdapter alloc] init];
                adapter = [MEGDTAdapter sharedInstance];
            }
        }
            break;
        default:
            break;
    }
    return adapter;
}

/// 从服务端请求配置
- (void)platformConfigIfRequestWithUrl:(NSString *)adRequestUrl {
    
    // 已初始化过则不再进行初始化
    if (self.isInit) {
        return;
    }
    
    // 如果url是空的,就给个默认url地址
    if (adRequestUrl == nil) {
        self.adReuqestUrl = @"https://mex-cdn-cn-beijing.oss-cn-beijing.aliyuncs.com/mediation.txt";
    } else {
        self.adReuqestUrl = adRequestUrl;
    }
//#warning 测试环境广告位
//    self.adReuqestUrl = @"https://mex-cdn-cn-beijing.oss-cn-beijing.aliyuncs.com/mediation.merge.txt";
    
    [self requestPlatformConfig];
}

// 请求各平台配置,这个请求比较耗时
- (void)requestPlatformConfig {
    _configIsRequesting = YES;
    // 从服务器读权重配置数据
    NSString *urlConfig = [NSString stringWithFormat:@"%@?media_id=2048&idfa=%@&platform=ios&sdkv=1.0.0", self.adReuqestUrl, [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]];
    
    DLog(@"urlConfig+-=-=-=-=-=-=-=-=%@", urlConfig);
    // 1. 先从文件中读取配置
    [self getConfigFromFile];
    
    // 2. 再从网络请求配置
    [[NBLHTTPManager sharedManager] requestObject:NBLResponseObjectType_JSON fromURL:urlConfig withParam:nil andResult:^(NSHTTPURLResponse *httpResponse, id responseObject, NSError *error, NSDictionary *dicParam) {
        self->_configIsRequesting = NO;
        
        if (error) {
            DLog(@"请求url：%@", urlConfig);
            DLog(@"错误数据：%@", error);
            // 若请求失败,则寻找本地缓存配置
            [self notifAppDidBecomeActive:nil];
            
            return;
        }
        // 解析成功，保存配置
        [responseObject writeToFile:FilePath_AllConfig atomically:YES];
        [self dispatchConfigDicWithResponseObj:responseObject];
#if 0
        MEConfigBaseModel *configModel = [MEConfigBaseModel modelObjectWithDictionary:responseObject];
        
        if (error) {
            DLog(@"请求url：%@", urlConfig);
            DLog(@"错误数据：%@", error);
            // 若请求失败,则寻找本地缓存配置
            [self notifAppDidBecomeActive:nil];
            
            return;
        }
        
        // 按优先级排序并筛选出iOS广告位
        self.configDic = [NSMutableDictionary dictionary];
        // 广告展示频次控制的配置字典
        self.sceneIdFrequencyDic = [NSMutableDictionary dictionary];
        for (MEConfigList *listInfo in configModel.list) {
            if ([listInfo.posid containsString:kConfigiOSSign]) {
                // 筛选出iOS并按优先级排序
                NSArray *sortedNetwork = [listInfo.network sortedArrayUsingComparator:^NSComparisonResult(MEConfigNetwork * obj1, MEConfigNetwork * obj2) {
                    return [obj1.order compare:obj2.order];
                }];
                listInfo.network = [NSArray arrayWithArray:sortedNetwork];
                if (listInfo.posid != nil) {
                    self.configDic[listInfo.posid] = listInfo;
                    // 需要变频的视图附上下标初始值0
                    if (listInfo.sortType.intValue == 4) {
                        self.sceneIdFrequencyDic[listInfo.posid] = @(0 % listInfo.sortParameter.count);
                    }
                }
            }
        }
        
        // 广告平台初始化用的配置
        for (MEConfigSdkInfo *sdkInfo in configModel.sdkInfo) {
            if ([sdkInfo.mid isEqualToString:kConfigiOSSign]) {
                self.sdkInfoArr = sdkInfo.info;
                self.configDic[@"sdkInfo"] = sdkInfo.info;
                break;
            }
        }
        
        // 初始化广告平台,并分配权重
        self.timeConfig = [NSDate date].timeIntervalSince1970;
        self.timeOut = configModel.timeout.doubleValue*1000;
        // 解析成功，保存配置
        [self.configDic writeToFile:FilePath_AllConfig atomically:YES];
#endif
//        if ([self parsePlatformPriority]) {
//            self.timeConfig = [NSDate date].timeIntervalSince1970;
//            self.timeOut = configModel.timeout.doubleValue*1000;
//            // 解析成功，保存配置
//            [self.configDic writeToFile:FilePath_AllConfig atomically:YES];
//        }
    }];
}

- (void)dispatchConfigDicWithResponseObj:(NSDictionary *)responseObject {
    MEConfigBaseModel *configModel = [MEConfigBaseModel modelObjectWithDictionary:responseObject];
    
    // 按优先级排序并筛选出iOS广告位
    self.configDic = [NSMutableDictionary dictionary];
    // 广告展示频次控制的配置字典
    self.sceneIdFrequencyDic = [NSMutableDictionary dictionary];
    for (MEConfigList *listInfo in configModel.list) {
        if ([listInfo.posid containsString:kConfigiOSSign]) {
            // 筛选出iOS并按优先级排序
            NSArray *sortedNetwork = [listInfo.network sortedArrayUsingComparator:^NSComparisonResult(MEConfigNetwork * obj1, MEConfigNetwork * obj2) {
                return [obj1.order compare:obj2.order];
            }];
            listInfo.network = [NSArray arrayWithArray:sortedNetwork];
            if (listInfo.posid != nil) {
                self.configDic[listInfo.posid] = listInfo;
                // 需要变频的视图附上下标初始值0
                if (listInfo.sortType.intValue == 4) {
                    self.sceneIdFrequencyDic[listInfo.posid] = @(0 % listInfo.sortParameter.count);
                }
            }
        }
    }
    
    // 广告平台初始化用的配置
    for (MEConfigSdkInfo *sdkInfo in configModel.sdkInfo) {
        if ([sdkInfo.mid isEqualToString:kConfigiOSSign]) {
            self.sdkInfoArr = sdkInfo.info;
            self.configDic[@"sdkInfo"] = sdkInfo.info;
            break;
        }
    }
    
    // 初始化广告平台,并分配权重
    self.timeConfig = [NSDate date].timeIntervalSince1970;
    self.timeOut = configModel.timeout.doubleValue*1000;
    // 解析成功，保存配置
//    [self.configDic writeToFile:FilePath_AllConfig atomically:YES];
}

/// 根据服务器返回配置信息初始化广告平台
/// @return 解析成功或失败
- (BOOL)parsePlatformPriority {
    // 分配权重
    // 取出iOS对应的配置
//    for (int i = 0; i < self.sdkInfoArr.count; i++) {
//        MEConfigInfo *info = self.sdkInfoArr[i];
//        // 头条穿山甲
//        if ([info.sdk isEqualToString:@"tt"]) {
//            self.BUADAPPId = info.appid;
//        }
//
//        // 广点通
//        if ([info.sdk isEqualToString:@"gdt"]) {
//            self.GDTAPPId = info.appid;
//        }
//
//        // 快手
//        if ([info.sdk isEqualToString:@"ks"]) {
//            self.KSAppId = info.appid;
//        }
//    }
    
    return [self initPlatform];
}

/// 初始化广告平台
- (BOOL)initPlatform {
    if (self.BUADAPPId == nil) {
        // 若没有启动id,则默认只启用对应平台测试的Appid
        self.BUADAPPId = kTestBUAD_APPID;
    }
    
    if (self.GDTAPPId == nil) {
        // 若没有启动id,则默认只启用对应平台测试的Appid
        self.GDTAPPId = kTestGDT_APPID;
    }
    
    if (self.KSAppId == nil) {
        // 若没有启动id,则默认只启用对应平台测试的Appid
        self.KSAppId = kTestKS_APPID;
    }
    
    if (self.BUADAPPId != nil && self.GDTAPPId != nil && self.KSAppId != nil) {
        // 用appId初始化各广告平台
        self.isInit = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kRequestConfigNotify object:@(YES)];
        [MEAdBaseManager lanuchAdPlatformWithBUADAppId:self.BUADAPPId GDTAppId:self.GDTAPPId KSAppId:self.KSAppId];
        return YES;
    }
    
    return NO;
}

/// 场景id转为穿山甲id,用于广告缓存
/// @param sceneId sceneId
- (NSString *)sceneIdExchangedBuadPosid:(NSString *)sceneId {
    NSString *posid = nil;
    // 先按场景找对应的广告位posid
    MEConfigList *listInfo = self.configDic[sceneId];
    if ([listInfo.posid isEqualToString:sceneId]) {
        for (int i = 0; i < listInfo.network.count; i++) {
            MEConfigNetwork *network = listInfo.network[i];
            if ([network.sdk isEqualToString:@"tt"]) {
                // 头条穿山甲
                posid = network.parameter.posid;
                break;
            }
        }
    }
    
    // 如果没有找到穿山甲的posid,则使用场景id
    if (posid == nil) {
        posid = sceneId;
    }
    return posid;
}

/// 若此次广告展示失败,返回备用展示的广告平台,没有则返回none
/// @param sceneId 场景id
/// @param agentType 当前展示失败的广告平台
- (MEAdAgentType)nextAdPlatformWithSceneId:(NSString *)sceneId currentPlatform:(MEAdAgentType)agentType {
    MEAdAgentType nextAgentType = MEAdAgentTypeNone;
    MEConfigList *listInfo = self.configDic[sceneId];
    if ([listInfo.posid isEqualToString:sceneId]) {
        for (int i = 0; i < listInfo.network.count; i++) {
            MEConfigNetwork *network = listInfo.network[i];
            if ([network.sdk isEqualToString:self.dicPlatformTypeName[@(agentType)]]) {
                continue;
            }
            if ([network.sdk isEqualToString:@"tt"]) {
                nextAgentType = MEAdAgentTypeBUAD;
                break;
            } else if ([network.sdk isEqualToString:@"gdt"]) {
                nextAgentType = MEAdAgentTypeGDT;
                break;
            } else if ([network.sdk isEqualToString:@"admob"]) {
                nextAgentType = MEAdAgentTypeAdmob;
                break;
            } else if ([network.sdk isEqualToString:@"ks"]) {
                nextAgentType = MEAdAgentTypeKS;
                break;
            }
        }
    }
    
    return nextAgentType;
}

// MARK: - 按广告位posid选择广告的逻辑,此次采用
/// 根据场景id和服务端配置的order选择要加载的广告平台和sceneId
/// @param sceneId 场景id
- (NSArray *)getFeedPosidByOrderWithPlatform:(MEAdAgentType)platformType SceneId:(NSString *)sceneId {
    NSDictionary *dict = [self assignPosidSceneIdPlatform:platformType sceneId:sceneId defaultSceneId:kDefaultFeedPosid];
    
    if (dict == nil) {
        return nil;
    }
    
    if (dict[@"posid"] != nil && dict[@"sceneId"] != nil && dict[@"platformType"]) {
        return @[dict[@"posid"], dict[@"sceneId"], dict[@"platformType"]];
    }
    
    return nil;
}

/// 根据广告平台获取激励视频的posid
/// @param platformType 广告平台
/// @param sceneId 场景id,详细在MEAdBaseManager.h可查
/// @return 数组 下标0表示广告平台的广告位id,下标1表示场景id
- (NSArray *)getRewardVideoPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId {
    NSDictionary *dict = [self assignPosidSceneIdPlatform:platformType sceneId:sceneId defaultSceneId:kDefaultRewardVideoPosid];
    
    if (dict == nil) {
        return nil;
    }
    
    if (dict[@"posid"] != nil && dict[@"sceneId"] != nil && dict[@"platformType"]) {
        return @[dict[@"posid"], dict[@"sceneId"], dict[@"platformType"]];
    }
    
    return nil;
}

/// 开屏广告
- (NSArray *)getSplashPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId {
    NSDictionary *dict = [self assignPosidSceneIdPlatform:platformType sceneId:sceneId defaultSceneId:kDefaultSplashPosid];
    
    if (dict == nil) {
        return nil;
    }
    
    if (dict[@"posid"] != nil && dict[@"sceneId"] != nil && dict[@"platformType"]) {
        return @[dict[@"posid"], dict[@"sceneId"], dict[@"platformType"]];
    }
    
    return nil;
}

/// 插屏广告
- (NSArray *)getInterstitialPosidByOrderWithPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId {
    NSString *posid = nil;
    NSDictionary *dict = [self assignPosidSceneIdPlatform:platformType sceneId:sceneId defaultSceneId:kDefaultInterstitialPosid];
    
    if (dict == nil) {
        return nil;
    }
    
    if (dict[@"posid"] != nil && dict[@"sceneId"] != nil && dict[@"platformType"]) {
        return @[dict[@"posid"], dict[@"sceneId"], dict[@"platformType"]];
    }
    
    return nil;
}

/// 分配广告平台和posid,以及查询不到posid时的默认posid
- (NSDictionary *)assignPosidSceneIdPlatform:(MEAdAgentType)platformType sceneId:(NSString *)sceneId defaultSceneId:(NSString *)defaultSceneId {
    NSString *posid = nil;
    
//    if (self.configDic == nil) {
//        // 表示未从服务端拉取下来配置,则执行默认广告方案
//        if (platformType == MEAdAgentTypeBUAD) {
//            posid = [[self.defaultPosidDict valueForKey:defaultSceneId] valueForKey:@"tt"];
//            platformType = MEAdAgentTypeBUAD;
//        } else if (platformType == MEAdAgentTypeGDT) {
//            posid = [[self.defaultPosidDict valueForKey:defaultSceneId] valueForKey:@"gdt"];
//            platformType = MEAdAgentTypeGDT;
//        } else {
//            // 未指定广告平台,默认拉广点通的
//            posid = [[self.defaultPosidDict valueForKey:defaultSceneId] valueForKey:@"gdt"];
//            platformType = MEAdAgentTypeGDT;
//        }
//        // 返回默认的广告位id,场景id及广告平台
//        return @{@"posid":posid, @"sceneId":defaultSceneId, @"platformType":@(platformType)};
//    }
    if (self.configDic == nil) {
        return nil;
    }
    
    // 先按场景找对应的广告位posid
    MEConfigList *listInfo = self.configDic[sceneId];
    
    // 先看该广告位是否需要控制频次
    if (self.sceneIdFrequencyDic[sceneId] && listInfo.sortParameter.count && platformType == MEAdAgentTypeNone) {
        NSString *platformStr = listInfo.sortParameter[[self.sceneIdFrequencyDic[sceneId] intValue]];
        if ([platformStr isEqualToString:@"tt"]) {
            platformType = MEAdAgentTypeBUAD;
        } else if ([platformStr isEqualToString:@"gdt"]) {
            platformType = MEAdAgentTypeGDT;
        } else if ([platformStr isEqualToString:@"admob"]) {
            platformType = MEAdAgentTypeAdmob;
        } else if ([platformStr isEqualToString:@"ks"]) {
            platformType = MEAdAgentTypeKS;
        }
    }
    
    if ([listInfo.posid isEqualToString:sceneId]) {
        if (platformType > MEAdAgentTypeNone && platformType < MEAdAgentTypeCount) {
            // 若指定了广告平台,则按优先级高的平台分配
            for (int i = 0; i < listInfo.network.count; i++) {
                MEConfigNetwork *network = listInfo.network[i];
                if (platformType == MEAdAgentTypeBUAD && [network.sdk isEqualToString:@"tt"]) {
                    // 头条穿山甲
                    posid = network.parameter.posid;
                    break;
                } else if (platformType == MEAdAgentTypeGDT && [network.sdk isEqualToString:@"gdt"]) {
                    // 广点通
                    posid = network.parameter.posid;
                    break;
                } else if (platformType == MEAdAgentTypeAdmob && [network.sdk isEqualToString:@"admob"]) {
                    // 谷歌
                    posid = network.parameter.posid;
                    break;
                } else if (platformType == MEAdAgentTypeKS && [network.sdk isEqualToString:@"ks"]) {
                    // 快手
                    posid = network.parameter.posid;
                    break;
                }
            }
        } else {
            // 若没指定平台,则按顺序选择优先级最高的
            if (listInfo.network.count) {
                MEConfigNetwork *network = listInfo.network[0];
                if ([network.sdk isEqualToString:@"tt"]) {
                    // 头条穿山甲
                    posid = network.parameter.posid;
                    platformType = MEAdAgentTypeBUAD;
                } else if ([network.sdk isEqualToString:@"gdt"]) {
                    // 广点通
                    posid = network.parameter.posid;
                    platformType = MEAdAgentTypeGDT;
                } else if ([network.sdk isEqualToString:@"admob"]) {
                    // 谷歌
                    posid = network.parameter.posid;
                    platformType = MEAdAgentTypeAdmob;
                } else if ([network.sdk isEqualToString:@"ks"]) {
                    // 快手
                    posid = network.parameter.posid;
                    platformType = MEAdAgentTypeKS;
                }
            }
        }
    }
    
    // 如果这里没分配到posid,则选择默认posid
//    if (posid == nil) {
//        MEConfigList *listInfo = self.configDic[defaultSceneId];
//        if (platformType > MEAdAgentTypeNone && platformType < MEAdAgentTypeCount) {
//            for (MEConfigNetwork *platform in listInfo.network) {
//                if (platformType == MEAdAgentTypeBUAD && [platform.sdk isEqualToString:@"tt"]) {
//                    posid = platform.parameter.posid;
//                    break;
//                } else if (platformType == MEAdAgentTypeGDT && [platform.sdk isEqualToString:@"gdt"]) {
//                    posid = platform.parameter.posid;
//                    break;
//                }
//            }
//        } else {
//            for (MEConfigNetwork *network in listInfo.network) {
//                if ([network.sdk isEqualToString:@"tt"]) {
//                    // 头条穿山甲
//                    posid = network.parameter.posid;
//                    platformType = MEAdAgentTypeBUAD;
//                    break;
//                } else if ([network.sdk isEqualToString:@"gdt"]) {
//                    // 广点通
//                    posid = network.parameter.posid;
//                    platformType = MEAdAgentTypeGDT;
//                    break;
//                }
//            }
//        }
//        sceneId = defaultSceneId;
//    }
    
    if (posid == nil) {
        return nil;
    }
    
    return @{@"posid":posid, @"sceneId":sceneId, @"platformType":@(platformType)};
}

// MARK: - Other
/// 改变广告使用频次
/// @param sceneId 场景id
- (void)changeAdFrequencyWithSceneId:(NSString *)sceneId {
    MEConfigList *listInfo = self.configDic[sceneId];
    if (self.sceneIdFrequencyDic[sceneId] && listInfo.sortParameter.count) {
        // 若场景id存在,则赋值
        self.sceneIdFrequencyDic[sceneId] = @(([self.sceneIdFrequencyDic[sceneId] intValue]+1) % listInfo.sortParameter.count);
    }
}

/// 获取顶层VC
- (UIViewController *)topVC {
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    if (![[UIApplication sharedApplication].windows containsObject:rootWindow]
        && [UIApplication sharedApplication].windows.count > 0) {
        rootWindow = [UIApplication sharedApplication].windows[0];
    }
    UIViewController *topVC = rootWindow.rootViewController;
    // 未读到keyWindow的rootViewController，则读UIApplicationDelegate的window，但该window不一定存在
    if (nil == topVC && [[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        topVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
