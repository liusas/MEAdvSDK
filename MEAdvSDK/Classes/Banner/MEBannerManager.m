//
//  MEBannerManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/9/9.
//

#import "MEBannerManager.h"
#import "MEBaseAdapter.h"
#import "MEAdNetworkManager.h"
#import "StrategyFactory.h"
@interface MEBannerManager ()<MEBaseAdapterBannerProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
/// sceneId:adapter,记录当前展示广告的adapter
@property (nonatomic, strong) NSMutableDictionary <NSString *, id<MEBaseAdapterProtocol>>*currentAdapters;
/// 此次信息流管理类分配到的广告平台模型数组,保证一次信息流广告有一个广告平台成功展示
@property (nonatomic, strong) NSMutableArray <StrategyResultModel *>*assignResultArr;

@property (nonatomic, copy) BannerViewReturnBlock bannerReturnBlock;
@property (nonatomic, copy) LoadBannerAdFinished finished;
@property (nonatomic, copy) LoadBannerAdFailed failed;

@property (nonatomic, assign) NSInteger requestCount;

@property (nonatomic, assign) NSTimeInterval refreshInterval;
@property (nonatomic, strong) UIViewController *rootVC;
@property (nonatomic, assign) CGSize targetSize;


// 只允许回调一次加载成功事件
@property (nonatomic, assign) BOOL hasSuccessfullyLoaded;

// 广告应该停止请求,可能原因1.超时, 2.已经成功拉取到广告
@property (nonatomic, assign) BOOL needToStop;

@end

@implementation MEBannerManager

+ (instancetype)shareInstance {
    static MEBannerManager *bannerManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bannerManager = [[MEBannerManager alloc] init];
    });
    return bannerManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.configManger = [MEConfigManager sharedInstance];
        self.currentAdapters = [NSMutableDictionary dictionary];
        self.assignResultArr = [NSMutableArray array];
        _needToStop = NO;
        
        self.refreshInterval = 5;
        self.targetSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), 100);
    }
    return self;
}

// 加载 banner 广告
- (void)showBannerViewWithSize:(CGSize)size
                             sceneId:(NSString *)sceneId
                            rootVC:(UIViewController *)rootVC
                   refreshInterval:(NSTimeInterval)interval
                        bannerView:(BannerViewReturnBlock)bannerReturnBlock
                          finished:(LoadBannerAdFinished)finished
                            failed:(LoadBannerAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    self.bannerReturnBlock = bannerReturnBlock;
    
    self.refreshInterval = interval;
    self.rootVC = rootVC;
    self.targetSize = size;
    
    _requestCount = 0;
    
    // 分配广告平台
    if (![self assignAdPlatformAndShow:sceneId platform:MEAdAgentTypeNone size:size]) {
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

// MARK: - MEBaseAdapterBannerProtocol
- (void)adapterBannerReturnView:(UIView *)bannerView {
    if (self.bannerReturnBlock) {
        self.bannerReturnBlock(bannerView);
    }
}

// 广告加载成功
- (void)adapterBannerLoadSuccess:(MEBaseAdapter *)adapter {
    if (self.hasSuccessfullyLoaded) {
        return;
    }
    // 只要有一个成功,就停止超时任务的执行
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

- (void)adapterBannerShowSuccess:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 控制广告平台展示频次
    [StrategyFactory changeAdFrequencyWithSceneId:adapter.sceneId];
    
    if (self.showFinishBlock) {
        self.showFinishBlock();
    }
}

// 广告加载失败
- (void)adapter:(MEBaseAdapter *)adapter bannerFailure:(NSError *)error {
    // 从数组中移除不需要处理的adapter
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    _requestCount++;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 拉取次数小于2次,可以在广告拉取失败的同时再次拉取
    if (_requestCount < 2 && self.assignResultArr.count == 0 && !self.needToStop) {
        // 下次选择的广告平台
        [self assignAdPlatformAndShow:adapter.sceneId platform:[self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType] size:self.targetSize];
        return;
    }
    
    if (self.assignResultArr.count == 0) {
        if (self.failed) {
            self.failed(error);
        }
        _requestCount = 0;
    }
}

// 广告关闭完成
- (void)adapterBannerCloseFinished:(MEBaseAdapter *)adapter {
    self.hasSuccessfullyLoaded = NO;
    self.needToStop = NO;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.closeBlock) {
        self.closeBlock();
    }
}

// 广告被点击
- (void)adapterBannerClicked:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.clickBlock) {
        self.clickBlock();
    }
}

// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShow:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform size:(CGSize)size {
    NSArray <StrategyResultModel *>*resultArr = [[StrategyFactory sharedInstance] getPosidBySortTypeWithPlatform:targetPlatform SceneId:sceneId];
    
    if (resultArr == nil || resultArr.count == 0) {
        return NO;
    }
    
    self.assignResultArr = [NSMutableArray arrayWithArray:resultArr];
    
    // 数组返回几个适配器就去请求几个平台的广告
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
            return [self assignAdPlatformAndShow:sceneId platform:nextPlatform size:size];
        }
        
        adapter.bannerDelegate = self;
        // 场景id
        adapter.sceneId = sceneId;
        adapter.isGetForCache = NO;
        adapter.sortType = [[MEConfigManager sharedInstance] getSortTypeFromSceneId:model.sceneId];
        
        [adapter showBannerViewWithSize:size posid:model.posid rootVC:self.rootVC refreshInterval:self.refreshInterval];
        
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
    log.st_t = AdLogAdType_Interstitial;
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
    NSError *error = [NSError errorWithDomain:@"request time out" code:0 userInfo:@{NSLocalizedDescriptionKey: @"插屏弹出失败"}];
    self.failed(error);
    [self stopAdapterAndRemoveFromAssignResultArr];
}

/// 停止assignResultArr中的adapter,然后删除adapter
- (void)stopAdapterAndRemoveFromAssignResultArr {
    self.needToStop = YES;
    // 停止其他adapter
    for (StrategyResultModel *model in self.assignResultArr) {
        id<MEBaseAdapterProtocol> adapter = [model.targetAdapterClass sharedInstance];
        if ([adapter respondsToSelector:@selector(stopInterstitialWithPosid:)]) {
            [adapter stopInterstitialWithPosid:model.posid];
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
