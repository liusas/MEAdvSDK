//
//  MERewardedVideoManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/8.
//

#import "MERewardedVideoManager.h"
#import "MEConfigManager.h"
#import "MEAdLogModel.h"
#import "MEAdNetworkManager.h"
#import "StrategyFactory.h"
#import "MEBaseAdapter.h"

@interface MERewardedVideoManager ()<MEBaseAdapterVideoProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
/// sceneId:adapter,记录当前展示广告的adapter
@property (nonatomic, strong) NSMutableDictionary <NSString *, id<MEBaseAdapterProtocol>>*currentAdapters;
/// 此次信息流管理类分配到的广告平台模型数组,保证一次信息流广告有一个广告平台成功展示
@property (nonatomic, strong) NSMutableArray <StrategyResultModel *>*assignResultArr;

@property (nonatomic, copy) LoadRewardVideoFinish finished;
@property (nonatomic, copy) LoadRewardVideoFailed failed;

@property (nonatomic, assign) NSInteger requestCount;

// 只允许回调一次加载成功事件
@property (nonatomic, assign) BOOL hasSuccessfullyLoaded;

// 广告应该停止请求,可能原因1.超时, 2.已经成功拉取到广告
@property (nonatomic, assign) BOOL needToStop;

@end

@implementation MERewardedVideoManager

+ (instancetype)shareInstance {
    static MERewardedVideoManager *videoManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        videoManager = [[MERewardedVideoManager alloc] init];
    });
    return videoManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.configManger = [MEConfigManager sharedInstance];
        self.currentAdapters = [NSMutableDictionary dictionary];
        self.assignResultArr = [NSMutableArray array];
        _needToStop = NO;
    }
    return self;
}

/// 加载激励视频
- (void)loadRewardedVideoWithSceneId:(NSString *)sceneId
                            finished:(LoadRewardVideoFinish)finished
                              failed:(LoadRewardVideoFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    // 分配广告平台
    if (![self assignAdPlatformAndShowLogic1WithSceneId:sceneId platform:MEAdAgentTypeNone]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
        return;
    }
    
    // 若超时时间为0,则不处理超时情况
    if (!self.configManger.adRequestTimeout) {
        return;
    }
    
    [self performSelector:@selector(requestTimeout) withObject:nil afterDelay:self.configManger.adRequestTimeout];
}

/// 展示激励视频
- (void)showRewardedVideoFromViewController:(UIViewController *)rootVC
                                    sceneId:(NSString *)sceneId {
    if (sceneId == nil) {
        NSError *error = [NSError errorWithDomain:@"sceneId can not be nil" code:0 userInfo:@{NSLocalizedDescriptionKey: @"视频弹出失败"}];
        self.failed(error);
        return;
    }
    
    for (NSString *posid in self.currentAdapters.allKeys) {
        id <MEBaseAdapterProtocol>adapter = self.currentAdapters[posid];
        
        if (adapter) {
            // 若当前正在播放视频,则禁止此次操作
            if (adapter.isTheVideoPlaying == YES) {
                return;
            }
            
            // 展示视频
            [adapter showRewardedVideoFromViewController:rootVC posid:posid];
            return;
        }
        
        // 到这表示没有可用的激励视频
        NSError *error = [NSError errorWithDomain:@"There are no ads to show" code:0 userInfo:@{NSLocalizedDescriptionKey: @"视频弹出失败"}];
        self.failed(error);
        break;
    }
}

/// 关闭当前视频
- (void)stopCurrentVideoWithSceneId:(NSString *)sceneId {
    for (NSString *posid in self.currentAdapters.allKeys) {
        id <MEBaseAdapterProtocol>adapter = self.currentAdapters[posid];
        
        if (adapter) {
            // 展示视频
            [adapter stopCurrentVideoWithPosid:posid];
            return;
        }
        
        // 没有找到相应的 adapter,无法关闭
        NSError *error = [NSError errorWithDomain:@"There are no ads to close" code:0 userInfo:@{NSLocalizedDescriptionKey: @"视频关闭失败"}];
        self.failed(error);
        break;
    }
}

- (BOOL)hasRewardedVideoAvailableWithSceneId:(NSString *)sceneId {
    for (NSString *posid in self.currentAdapters.allKeys) {
        id <MEBaseAdapterProtocol>adapter = self.currentAdapters[posid];
        
        if (adapter) {
            return [adapter hasRewardedVideoAvailableWithPosid:posid];
        }
        break;
    }
    
    return NO;
}

// MARK: - MEBaseAdapterVideoProtocol
- (void)adapterVideoLoadSuccess:(MEBaseAdapter *)adapter {
    if (self.hasSuccessfullyLoaded) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestTimeout) object:nil];
    
    self.hasSuccessfullyLoaded = YES;
    
    // 添加adapter到当前管理adapter的字典
    self.currentAdapters[adapter.posid] = adapter;
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    // 停止其他adapter
    [self stopAdapterAndRemoveFromAssignResultArr];
    
    // 拉取成功后,置0
    _requestCount = 0;
    
    if (self.finished) {
        self.finished();
    }
}

- (void)adapterVideoDidDownload:(MEBaseAdapter *)adapter {
    if (self.didDownloadBlock) {
        self.didDownloadBlock();
    }
}

/// 展现video成功
- (void)adapterVideoShowSuccess:(MEBaseAdapter *)adapter {
    // 控制广告平台展示频次
    [StrategyFactory changeAdFrequencyWithSceneId:adapter.sceneId];
    
    if (self.showFinish) {
        self.showFinish();
    }
}

/// 展现video失败
- (void)adapter:(MEBaseAdapter *)adapter videoShowFailure:(NSError *)error {
    // 从数组中移除不需要处理的adapter
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    // 只要有成功的,就不报失败信息
    if (self.hasSuccessfullyLoaded) {
        return;
    }
    
    _requestCount++;
    
    // 拉取次数小于2次,次数多了就太慢了,可以在广告拉取失败的同时再次拉取
    // 适用于串行,每次只拉取一个广告的情况,并行大于等于 2 个就不符合以下条件了
    if (_requestCount < 2 && self.assignResultArr.count == 0 && !self.needToStop) {
        // 选择广告位对应的广告平台数组里面的下一个广告平台
        [self assignAdPlatformAndShowLogic1WithSceneId:adapter.sceneId platform:[self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType]];
        return;
    }
    
    // 执行完所有策略后依然失败,则返回失败信息
    if (self.assignResultArr.count == 0) {
        if (self.failed) {
            self.failed(error);
        }
        _requestCount = 0;
    }
}

/// 视频广告播放完毕
- (void)adapterVideoFinishPlay:(MEBaseAdapter *)adapter {
    if (self.finishPlayBlock) {
        self.finishPlayBlock();
    }
}

/// video被点击
- (void)adapterVideoClicked:(MEBaseAdapter *)adapter {
    if (self.clickBlock) {
        self.clickBlock();
    }
}

/// video关闭事件
- (void)adapterVideoClose:(MEBaseAdapter *)adapter {
    self.hasSuccessfullyLoaded = NO;
    self.needToStop = NO;
    
    if (self.closeBlock) {
        self.closeBlock();
    }
}

// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShowLogic1WithSceneId:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
    NSArray <StrategyResultModel *>*resultArr = [[StrategyFactory sharedInstance] getPosidBySortTypeWithPlatform:targetPlatform SceneId:sceneId];
    
    if (resultArr == nil || resultArr.count == 0) {
        return NO;
    }
    
    self.assignResultArr = [NSMutableArray arrayWithArray:resultArr];
    
    // 数组返回几个适配器就去请求几个平台的广告,只有并行请求的策略下,数组中会有多个元素
    for (StrategyResultModel *model in resultArr) {
        id <MEBaseAdapterProtocol>adapter = self.currentAdapters[model.posid];
        if ([adapter isKindOfClass:model.targetAdapterClass]) {
            // 若当前有可用的adapter则直接拿来用
        } else {
            adapter = [model.targetAdapterClass sharedInstance];
        }
        
        // 若此时adapter依然为空,则表示没有相应广告平台的适配器,若策略是每次只请求一个广告平台,则继续找下一个广告平台
        if (adapter == nil && resultArr.count == 1) {
            MEAdAgentType nextPlatform = [self.configManger nextAdPlatformWithSceneId:sceneId currentPlatform:model.platformType];
            if (nextPlatform == MEAdAgentTypeAll) {
                // 没有分配到合适广告
                return NO;
            }
            
            // 找到下一个广告平台则指定出这个平台的广告
            return [self assignAdPlatformAndShowLogic1WithSceneId:sceneId platform:nextPlatform];
        }
        
        adapter.videoDelegate = self;
        // 场景id
        adapter.sceneId = sceneId;
        adapter.isGetForCache = NO;
        adapter.sortType = [[MEConfigManager sharedInstance] getSortTypeFromSceneId:model.sceneId];
        [adapter loadRewardVideoWithPosid:model.posid];
        // 请求日志上报
        [self trackRequestWithSortType:adapter.sortType sceneId:sceneId platformType:model.platformType];
    }
    
    return YES;
}

// MARK: - Private
// 追踪请求上报
- (void)trackRequestWithSortType:(NSInteger)sortType
                         sceneId:(NSString *)sceneId
                    platformType:(MEAdAgentType)platformType {
    // 发送请求数据上报
    MEAdLogModel *log = [MEAdLogModel new];
    log.event = AdLogEventType_Request;
    log.st_t = AdLogAdType_RewardVideo;
    log.so_t = sortType;
    log.posid = sceneId;
    log.network = [MEAdNetworkManager getNetworkNameFromAgentType:platformType];
    log.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", log.posid, log.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:log];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/// 请求超时
- (void)requestTimeout {
    NSError *error = [NSError errorWithDomain:@"sceneId can not be nil" code:0 userInfo:@{NSLocalizedDescriptionKey: @"视频弹出失败"}];
    self.failed(error);
    [self stopAdapterAndRemoveFromAssignResultArr];
}

/// 停止assignResultArr中的adapter,然后删除adapter
- (void)stopAdapterAndRemoveFromAssignResultArr {
    self.needToStop = YES;
    // 停止其他adapter
    for (StrategyResultModel *model in self.assignResultArr) {
        id<MEBaseAdapterProtocol> adapter = [model.targetAdapterClass sharedInstance];
        if ([adapter respondsToSelector:@selector(stopCurrentVideoWithPosid:)]) {
            [adapter stopCurrentVideoWithPosid:model.posid];
        }
    }
    [self.assignResultArr removeAllObjects];
}

// 删除分配结果数组中的元素
- (void)removeAssignResultArrObjectWithAdapter:(id<MEBaseAdapterProtocol>)adapter {
    [self.assignResultArr enumerateObjectsUsingBlock:^(StrategyResultModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([adapter isKindOfClass:[obj.targetAdapterClass class]]) {
            *stop = YES;
            if (*stop == YES) {
                [self.assignResultArr removeObject:obj];
            }
        }
    }];
}

@end
