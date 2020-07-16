//
//  MEConfigManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import "MEConfigManager.h"
#import "MEAdNetworkManager.h"
#import "NBLHTTPManager.h"
#import <AdSupport/AdSupport.h>
#import "MEAdLogModel.h"
#import "StrategyFactory.h"

@interface MEConfigManager ()

@property (nonatomic, assign) NSTimeInterval timeConfig; /// 获取配置的时间
@property (nonatomic, assign) NSTimeInterval timeOut; /// 配置过期时长

@property (nonatomic, copy) NSArray *sdkInfoArr; /// 配置的广告平台,用于初始化
/// 各广告位的默认posid
@property (nonatomic, copy) NSDictionary *defaultPosidDict;

/// 初始化完成的block
@property (nonatomic, copy) ConfigManangerFinished finished;

@end

@implementation MEConfigManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _configIsRequesting = NO;
        // 监听app激活通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifAppWillEnterForegroundActive:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}


// MARK: - Notification
/// 监听app即将进入前台,检测广告日志并上传
- (void)notifAppWillEnterForegroundActive: (NSNotification *)notify {
    // 检测若广告日志超过20条,则上传
    [MEAdLogModel checkLogsAndUploadToServer];
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

+ (void)loadWithAppID:(NSString *)appid finished:(void (^) (void))finished {
    // 已初始化过则不再进行初始化
    if ([MEConfigManager sharedInstance].isInit == YES) {
        return;
    }
    
    MEConfigManager *manager = [MEConfigManager sharedInstance];
    manager.platformAppid = appid;
    manager.finished = finished;
    
    // 读取磁盘缓存
    [manager readDiskCache];
    
    // 尝试初始化,无论成功或失败,都去服务端拉取一次最新的配置
    [manager tryToLaunchPlatform];
    
    // 若缓存上没有请求url,则使用默认url
    if (manager.adReuqestUrl == nil) {
        manager.adReuqestUrl = kBaseRequestURL;
    }
    
    [manager requestPlatformConfig];
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
            if ([MEAdNetworkManager getAgentTypeFromNetworkName:network.sdk] == MEAdAgentTypeBUAD) {
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
            if ([network.sdk isEqualToString:[MEAdNetworkManager getNetworkNameFromAgentType:agentType]]) {
                continue;
            }
            
            nextAgentType = [MEAdNetworkManager getAgentTypeFromNetworkName:network.sdk];
            if (nextAgentType != MEAdAgentTypeNone) {
                break;
            }
        }
    }
    
    return nextAgentType;
}

/// 获取该sceneId下的sortType是多少
- (NSInteger)getSortTypeFromSceneId:(NSString *)sceneId {
    MEConfigList *listInfo = self.configDic[sceneId];
    if (listInfo) {
        return listInfo.sortType.integerValue;
    }
    
    return 1;
}

// MARK: - Network
// 请求各平台配置,这个请求比较耗时
- (void)requestPlatformConfig {
    _configIsRequesting = YES;
    // 从服务器读权重配置数据
    NSString *urlConfig = [NSString stringWithFormat:@"%@?media_id=%@&idfa=%@&platform=ios&sdkv=%@", self.adReuqestUrl, self.platformAppid, [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString], @"1.0.0"];
    
    // 请求配置
    [[NBLHTTPManager sharedManager] requestObject:NBLResponseObjectType_JSON fromURL:urlConfig withParam:nil andResult:^(NSHTTPURLResponse *httpResponse, id responseObject, NSError *error, NSDictionary *dicParam) {
        self->_configIsRequesting = NO;
        
        if (error) {
            DLog(@"广告配置拉取失败：%@", error);
            // 若请求失败,则寻找本地缓存配置,上一步已经读取了缓存配置给configDic
            if (self.isInit == false) {
                [self assignPlatform];
            }
            return;
        }
        // 解析成功，保存配置
        [responseObject writeToFile:FilePath_AllConfig atomically:YES];
        [self dispatchConfigDicWithResponseObj:responseObject];
        if (self.isInit == false) {
            [self assignPlatform];
        }
    }];
}

// MARK: - Private
// 读取磁盘缓存
- (void)readDiskCache {
    NSDictionary *responseObject = [NSMutableDictionary dictionaryWithContentsOfFile:FilePath_AllConfig];
    
    if (responseObject == nil) {
    } else {
        // 将磁盘中缓存的广告配置传入内存中
        // configDic,按优先级排序并筛选出iOS广告位
        // sceneIdFrequencyDic,广告展示频次控制的配置字典,{posid : index},每次成功展示广告后index+1
        // sdkInfoArr,广告平台的信息,每个元素有sdk(平台名称缩写),appid(广告平台对应的appid)
        [self dispatchConfigDicWithResponseObj:responseObject];
    }
}

// 尝试初始化,返回初始化成功或失败
- (BOOL)tryToLaunchPlatform {
    // 如果磁盘中没有配置信息,则不处理,等待请求拉取下来后再初始化
    if (self.configDic == nil) {
        return NO;
    }
    self.sdkInfoArr = self.configDic[@"sdkInfo"];
    return [self assignPlatform];
}

- (void)dispatchConfigDicWithResponseObj:(NSDictionary *)responseObject {
    MEConfigBaseClass *configModel = [MEConfigBaseClass modelObjectWithDictionary:responseObject];
    
    // 按优先级排序并筛选出iOS广告位
    self.configDic = [NSMutableDictionary dictionary];
    // 广告展示频次控制的配置字典
    for (MEConfigList *listInfo in configModel.list) {
        if ([listInfo.posid containsString:self.platformAppid]) {
            // 筛选出iOS并按优先级排序
            NSArray *sortedNetwork = [listInfo.network sortedArrayUsingComparator:^NSComparisonResult(MEConfigNetwork * obj1, MEConfigNetwork * obj2) {
                return [obj1.order compare:obj2.order];
            }];
            listInfo.network = [NSArray arrayWithArray:sortedNetwork];
            if (listInfo.posid != nil) {
                self.configDic[listInfo.posid] = listInfo;
                // 需要变频的视图附上下标初始值0
                if (listInfo.sortType.intValue == 4) {
                    [StrategyFactory sharedInstance].sceneIdFrequencyDic[listInfo.posid] = @(0 % listInfo.sortParameter.count);
                }
            }
        }
    }
    
    // 广告平台初始化用的配置
    for (MEConfigSdkInfo *sdkInfo in configModel.sdkInfo) {
        if ([sdkInfo.mid isEqualToString:self.platformAppid]) {
            self.sdkInfoArr = sdkInfo.info;
            self.configDic[@"sdkInfo"] = sdkInfo.info;
            break;
        }
    }
    
    // 将磁盘缓存中存储的信息保存在内存中,因为MEConfigMnager类是个单例,所以在程序使用期间不会释放
    self.timeConfig = [NSDate date].timeIntervalSince1970;
    self.timeOut = configModel.config.timeout.doubleValue * 1000.f;
    self.adRequestTimeout = configModel.config.adAdkReqTimeout.doubleValue / 1000.f;
    self.adReuqestUrl = configModel.config.protoUrl;
    self.adLogUrl = configModel.config.reportUrl;
    self.developerUrl = configModel.config.developerUrl;
}

/// 根据配置信息初始化广告平台
/// @return 解析成功或失败
- (BOOL)assignPlatform {
    // 将服务器返回的平台配置信息存入`MEAdNetworkManager`
    [MEAdNetworkManager configAdNetworksWithConfigInfo:self.sdkInfoArr];
    return [self initPlatform];
}

/// 初始化广告平台
- (BOOL)initPlatform {
    if ([MEAdNetworkManager launchAdNetwork]) {
        self.isInit = YES;
        self.finished();
        return YES;
    }
    return NO;
}

// MARK: - Other
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
