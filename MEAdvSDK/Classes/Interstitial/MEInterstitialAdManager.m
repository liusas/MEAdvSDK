//
//  MEInterstitialAdManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/12/13.
//

#import "MEInterstitialAdManager.h"
#import "MEBaseAdapter.h"
#import "MEAdNetworkManager.h"
#import "StrategyFactory.h"

@interface MEInterstitialAdManager ()<MEBaseAdapterInterstitialProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
/// sceneId:adapter,记录当前展示广告的adapter
@property (nonatomic, strong) NSMutableDictionary <NSString *, id<MEBaseAdapterProtocol>>*currentAdapters;
/// 此次信息流管理类分配到的广告平台模型数组,保证一次信息流广告有一个广告平台成功展示
@property (nonatomic, strong) NSMutableArray <StrategyResultModel *>*assignResultArr;

@property (nonatomic, copy) LoadInterstitialAdFinished finished;
@property (nonatomic, copy) LoadInterstitialAdFailed failed;

@property (nonatomic, assign) NSInteger requestCount;

/// 是否展示误点按钮
@property (nonatomic, assign) BOOL showFunnyBtn;

// 只允许回调一次加载成功事件
@property (nonatomic, assign) BOOL hasSuccessfullyLoaded;

// 广告应该停止请求,可能原因1.超时, 2.已经成功拉取到广告
@property (nonatomic, assign) BOOL needToStop;

@end

@implementation MEInterstitialAdManager

+ (instancetype)shareInstance {
    static MEInterstitialAdManager *interstitialManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        interstitialManager = [[MEInterstitialAdManager alloc] init];
    });
    return interstitialManager;
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

/// 展示插屏广告
- (void)showInterstitialAdvWithSceneId:(NSString *)sceneId
                          showFunnyBtn:(BOOL)showFunnyBtn
                        Finished:(LoadInterstitialAdFinished)finished
                          failed:(LoadInterstitialAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    self.showFunnyBtn = showFunnyBtn;
    // 分配广告平台
    if (![self assignAdPlatformAndShow:sceneId platform:MEAdAgentTypeNone]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
        return;
    }
    
    // 若超时时间为0,则不处理超时情况
    if (!self.configManger.adRequestTimeout) {
        return;
    }
    
    [self performSelector:@selector(stopAdapterAndRemoveFromAssignResultArr) withObject:nil afterDelay:self.configManger.adRequestTimeout];
}

- (void)stopInterstitialRender {
    [self stopAdapterAndRemoveFromAssignResultArr];
}

// MARK: - MEBaseAdapterInterstitialProtocol
// 插屏广告加载成功
- (void)adapterInterstitialLoadSuccess:(MEBaseAdapter *)adapter {
    if (self.hasSuccessfullyLoaded) {
        return;
    }
    // 只要有一个成功,就停止超时任务的执行
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopAdapterAndRemoveFromAssignResultArr) object:nil];

    self.hasSuccessfullyLoaded = YES;
    
    // 添加adapter到当前管理adapter的字典
    self.currentAdapters[adapter.sceneId] = adapter;
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    // 停止其他adapter
    [self stopAdapterAndRemoveFromAssignResultArr];
}

- (void)adapterInterstitialShowSuccess:(MEBaseAdapter *)adapter {
    // 拉取成功后,置0
    _requestCount = 0;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 控制广告平台展示频次
    [StrategyFactory changeAdFrequencyWithSceneId:adapter.sceneId];
    
    if (self.finished) {
        self.finished();
    }
}

// 插屏广告加载失败
- (void)adapter:(MEBaseAdapter *)adapter interstitialLoadFailure:(NSError *)error {
    // 从数组中移除不需要处理的adapter
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    _requestCount++;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 拉取次数小于2次,可以在广告拉取失败的同时再次拉取
    if (_requestCount < 2 && self.assignResultArr.count == 0 && !self.needToStop) {
        // 下次选择的广告平台
        [self assignAdPlatformAndShow:adapter.sceneId platform:[self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType]];
        return;
    }
    
    if (self.assignResultArr.count == 0) {
        _requestCount = 0;
        
        if (self.failed) {
            self.failed(error);
        }
    }
}

// 插屏广告从外部返回原生应用
- (void)adapterInterstitialDismiss:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    if (self.clickThenDismiss) {
        self.clickThenDismiss();
    }
}

// 插屏广告关闭完成
- (void)adapterInterstitialCloseFinished:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.closeBlock) {
        self.closeBlock();
    }
}

// 插屏广告被点击
- (void)adapterInterstitialClicked:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.clickBlock) {
        self.clickBlock();
    }
}

// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShow:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
    NSArray <StrategyResultModel *>*resultArr = [[StrategyFactory sharedInstance] getPosidBySortTypeWithPlatform:targetPlatform SceneId:sceneId];
    
    if (resultArr == nil || resultArr.count == 0) {
        return NO;
    }
    
    self.assignResultArr = [NSMutableArray arrayWithArray:resultArr];
    
    // 数组返回几个适配器就去请求几个平台的广告
    for (StrategyResultModel *model in resultArr) {
        id <MEBaseAdapterProtocol>adapter = self.currentAdapters[model.sceneId];
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
            return [self assignAdPlatformAndShow:sceneId platform:nextPlatform];
        }
        
        adapter.interstitialDelegate = self;
        // 场景id
        adapter.sceneId = sceneId;
        adapter.isGetForCache = NO;
        adapter.sortType = [[MEConfigManager sharedInstance] getSortTypeFromSceneId:model.sceneId];
        [adapter showInterstitialViewWithPosid:model.posid showFunnyBtn:self.showFunnyBtn];
    }
    
    return YES;
}

// MARK: - Private
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
