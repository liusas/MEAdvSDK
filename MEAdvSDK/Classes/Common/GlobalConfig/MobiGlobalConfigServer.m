//
//  MobiGlobalConfigServer.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/23.
//

#import "MobiGlobalConfigServer.h"
#import "MobiGlobalConfig.h"
#import "MEAdvConfig.h"
#import "MPDeviceInformation.h"
#import "MobiHTTPNetworkSession.h"
#import "MobiURLRequest.h"
#import "MEAdNetworkManager.h"
#import "MEConfigBaseClass.h"
#import "MPError.h"
#import "MPLogging.h"
#import "StrategyFactory.h"
#import "NSString+MPAdditions.h"
#import "NSDictionary+MPAdditions.h"

static NSString *_defaultConfigName = @"mb_config";
static NSString *_defaultConfigFileType = @"txt";
static NSString *_getConfigBefore = @"_getConfigBefore";

static dispatch_queue_t file_access_creation_queue() {
    static dispatch_queue_t file_access_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        file_access_creation_queue = dispatch_queue_create("com.mobiexchanger.fileaccess.queue", DISPATCH_QUEUE_SERIAL);
    });
    
    return file_access_creation_queue;
}

@interface MobiGlobalConfigServer ()

@property (nonatomic, assign) NSTimeInterval timeConfig; /// 获取配置的时间
@property (nonatomic, assign) NSTimeInterval timeOut; /// 配置过期时长

@property (nonatomic, copy) NSArray *sdkInfoArr; /// 配置的广告平台,用于初始化

/// 初始化完成的block
@property (nonatomic, copy) ConfigManangerFinished finished;

/// 是否正在请求
@property (nonatomic, assign) BOOL loading;

/// 广告请求URL
@property (nonatomic, copy) NSString *adReuqestUrl;

@property (nonatomic, strong) NSURLSessionTask *task;

@property (nonatomic, strong) MobiPubConfiguration *configuration;

@end

@implementation MobiGlobalConfigServer

/// 从服务端请求平台配置信息
- (void)loadWithConfiguration:(MobiPubConfiguration *)configuration finished:(ConfigManangerFinished)finished {
    // 已初始化过则不再进行初始化
    if ([MobiGlobalConfig sharedInstance].isInit == YES) {
        return;
    }
    
    // appid 为空,初始化失败
    if (configuration.appid == nil) {
        return;
    }
    
    [MobiGlobalConfig sharedInstance].platformAppid = configuration.appid;
    
    self.finished = finished;
    
    self.configuration = configuration;
    
    // 读取磁盘缓存
    [self readDiskCache];
    
    // 尝试初始化,无论成功或失败,都去服务端拉取一次最新的配置
    [self tryToLaunchPlatform];
    
    // 若缓存上没有请求url,则使用默认url
    if (self.adReuqestUrl == nil) {
        self.adReuqestUrl = kBaseRequestURL;
    }
    
    [self requestPlatformConfig:configuration];
}

- (void)cancel
{
    self.loading = NO;
    [self.task cancel];
    self.task = nil;
}

// MARK: - Network
// 请求各平台配置,这个请求比较耗时
- (void)requestPlatformConfig:(MobiPubConfiguration *)configuration {
    _loading = YES;
    // 从服务器读权重配置数据
    NSString *urlConfig = [NSString stringWithFormat:@"%@?media_id=%@&idfa=%@&platform=ios&sdkv=%@", self.adReuqestUrl, configuration.appid, [MPDeviceInformation idfa], kSDKVersion];
    
    MobiURLRequest * request = [MobiURLRequest requestWithURL:[NSURL URLWithString:urlConfig]];
    
    // 请求配置
    __weak __typeof__(self) weakSelf = self;
//    NSLog(@"请求开始=============%f", CACurrentMediaTime());
    self.task = [MobiHTTPNetworkSession startTaskWithHttpRequest:request responseHandler:^(NSData * _Nonnull data, NSHTTPURLResponse * _Nonnull response) {
        __typeof__(self) strongSelf = weakSelf;
//        NSLog(@"请求结束=============%f", CACurrentMediaTime());
        [strongSelf didFinishLoadingWithData:data];
    } errorHandler:^(NSError * _Nonnull error) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf didFailWithError:error];
    }];
}

#pragma mark - Handlers

- (void)didFailWithError:(NSError *)error {
    // Do not record a logging event if we failed.
    self.loading = NO;
    if ([MobiGlobalConfig sharedInstance].isInit == false) {
        [self assignPlatform];
    }
}

- (void)didFinishLoadingWithData:(NSData *)data {
    self.loading = NO;
    
    NSError * error = nil;
    NSDictionary * responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) {
        NSError * parseError = [NSError adResponseFailedToParseWithError:error];
        [self didFailWithError:parseError];
        return;
    }

    dispatch_sync(file_access_creation_queue(), ^{
//        [responseObject mb_toJsonSaveWithFilename:_defaultConfigName fileType:_defaultConfigFileType];
        BOOL result = [responseObject writeToFile:FilePath_AllConfig atomically:YES];
        if (result) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:_getConfigBefore];
        }
    });
    
    [self dispatchConfigDicWithResponseObj:responseObject];
    if ([MobiGlobalConfig sharedInstance].isInit == false) {
        [self assignPlatform];
    }
    
}

// MARK: - Private
// 读取磁盘缓存
- (void)readDiskCache {
    NSDictionary *responseObject = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:_getConfigBefore] == YES) {
        responseObject = [NSMutableDictionary dictionaryWithContentsOfFile:FilePath_AllConfig];
    } else {
        responseObject = [_defaultConfigName dicFromFileWithType:_defaultConfigFileType];
    }
    
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
    if ([MobiGlobalConfig sharedInstance].configDic == nil) {
        return NO;
    }
    self.sdkInfoArr = [MobiGlobalConfig sharedInstance].configDic[@"sdkInfo"];
    return [self assignPlatform];
}

- (void)dispatchConfigDicWithResponseObj:(NSDictionary *)responseObject {
    MEConfigBaseClass *configModel = [MEConfigBaseClass modelObjectWithDictionary:responseObject];
    
    // 按优先级排序并筛选出iOS广告位
    [MobiGlobalConfig sharedInstance].configDic = [NSMutableDictionary dictionary];
    // 广告展示频次控制的配置字典
    for (MEConfigList *listInfo in configModel.list) {
        if ([listInfo.posid containsString:[MobiGlobalConfig sharedInstance].platformAppid]) {
            // 筛选出iOS并按优先级排序
            NSArray *sortedNetwork = [listInfo.network sortedArrayUsingComparator:^NSComparisonResult(MEConfigNetwork * obj1, MEConfigNetwork * obj2) {
                return [obj1.order compare:obj2.order];
            }];
            listInfo.network = [NSArray arrayWithArray:sortedNetwork];
            if (listInfo.posid != nil) {
                [MobiGlobalConfig sharedInstance].configDic[listInfo.posid] = listInfo;
                // 需要变频的视图附上下标初始值0
                if (listInfo.sortType.intValue == 4) {
                    // 将 orderParameter 变成存放数组下标的形式
                    [StrategyFactory sharedInstance].sceneIdFrequencyDic[listInfo.posid] = @(0 % listInfo.orderParameter.count);
                    
                    if ([self orderParameterWithListInfo:listInfo] != nil) {
                        listInfo.orderParameter = [NSArray arrayWithArray:[self orderParameterWithListInfo:listInfo]];
                    }
                }
            }
        }
    }
    
    // 广告平台初始化用的配置
    for (MEConfigSdkInfo *sdkInfo in configModel.sdkInfo) {
        if ([sdkInfo.mid isEqualToString:[MobiGlobalConfig sharedInstance].platformAppid]) {
            self.sdkInfoArr = sdkInfo.info;
            [MobiGlobalConfig sharedInstance].configDic[@"sdkInfo"] = sdkInfo.info;
            break;
        }
    }
    
    // 将磁盘缓存中存储的信息保存在内存中,因为MEConfigMnager类是个单例,所以在程序使用期间不会释放
    self.timeConfig = [NSDate date].timeIntervalSince1970;
    self.timeOut = configModel.config.timeout.doubleValue * 1000.f;
    
    MobiGlobalConfig *config = [MobiGlobalConfig sharedInstance];
    config.adRequestTimeout = configModel.config.adAdkReqTimeout.doubleValue / 1000.f;
    config.adLogUrl = configModel.config.reportUrl;
    config.developerUrl = configModel.config.developerUrl;
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
        MobiGlobalConfig *shareConfig = [MobiGlobalConfig sharedInstance];
        // 若之前已经初始化成功,则这次就偷偷初始化,不回调上层
        BOOL initialized = shareConfig.isInit;
        shareConfig.isInit = YES;
        if (initialized == NO) {
            self.finished(shareConfig.configDic);
        }
        return YES;
    }
    return NO;
}

#warning 这个算法时间复杂度有点高,需要优化
- (NSArray *)orderParameterWithListInfo:(MEConfigList *)listInfo {
    NSMutableArray *sortArr = [NSMutableArray array];
    for (int i = 0; i < listInfo.orderParameter.count; i++) {
        for (int j = 0; j < listInfo.network.count; j++) {
            MEConfigNetwork *network = listInfo.network[j];
//            NSString *indexStr = [NSString stringWithFormat:@"%@_%@", network.sdk, listInfo.orderParameter[i]];
            if ([listInfo.orderParameter[i] isEqualToString:network.ntName]) {
                [sortArr addObject:@(j)];
            }
        }
    }
    return sortArr;
}

- (void)dealloc
{
    [self.task cancel];
}

@end
