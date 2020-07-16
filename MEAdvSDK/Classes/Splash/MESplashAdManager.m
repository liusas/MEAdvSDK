//
//  MESplashAdManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/27.
//

#import "MESplashAdManager.h"
#import "MEBaseAdapter.h"
#import "MEAdLogModel.h"
#import "MEAdNetworkManager.h"
#import "StrategyFactory.h"

@interface MESplashAdManager ()<MEBaseAdapterSplashProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
/// sceneId:adapter,记录当前展示广告的adapter
@property (nonatomic, strong) NSMutableDictionary <NSString *, id<MEBaseAdapterProtocol>>*currentAdapters;
/// 此次信息流管理类分配到的广告平台模型数组,保证一次信息流广告有一个广告平台成功展示
@property (nonatomic, strong) NSMutableArray <StrategyResultModel *>*assignResultArr;

@property (nonatomic, copy) LoadSplashAdFinished finished;
@property (nonatomic, copy) LoadSplashAdFailed failed;

// 只允许回调一次加载成功事件
@property (nonatomic, assign) BOOL hasSuccessfullyLoaded;

// 广告应该停止请求,可能原因1.超时, 2.已经成功拉取到广告
@property (nonatomic, assign) BOOL needToStop;

@end

@implementation MESplashAdManager

+ (instancetype)shareInstance {
    static MESplashAdManager *splashManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        splashManager = [[MESplashAdManager alloc] init];
    });
    return splashManager;
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

/// 展示开屏广告
- (void)showSplashAdvWithSceneId:(NSString *)sceneId
                           delay:(NSTimeInterval)delay
                        Finished:(LoadSplashAdFinished)finished
                          failed:(LoadSplashAdFailed)failed {
    [self showSplashAdvWithSceneId:sceneId delay:delay bottomView:nil Finished:finished failed:failed];
}

- (void)showSplashAdvWithSceneId:(NSString *)sceneId
                           delay:(NSTimeInterval)delay
                      bottomView:(UIView *)bottomView
                        Finished:(LoadSplashAdFinished)finished
                          failed:(LoadSplashAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    // 分配广告平台
    if (![self assignAdPlatformAndShow:sceneId platform:MEAdAgentTypeNone delay:delay bottomView:bottomView]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
    }
}

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender:(NSString *)sceneId {
    id <MEBaseAdapterProtocol>adapter = self.currentAdapters[sceneId];
    if (adapter) {
        [adapter stopSplashRenderWithPosid:adapter.posid];
        [self.currentAdapters removeObjectForKey:sceneId];
        adapter = nil;
    }
}

// MARK: - MEBaseAdapterSplashProtocol
/// 开屏展示成功
- (void)adapterSplashShowSuccess:(MEBaseAdapter *)adapter {
    if (self.hasSuccessfullyLoaded) {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopAdapterAndRemoveFromAssignResultArr) object:nil];
    
    self.hasSuccessfullyLoaded = YES;
    
    // 添加adapter到当前管理adapter的字典
    self.currentAdapters[adapter.sceneId] = adapter;
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    // 停止其他adapter
    [self stopAdapterAndRemoveFromAssignResultArr];
    
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 控制广告平台展示频次
    [StrategyFactory changeAdFrequencyWithSceneId:adapter.sceneId];
    
    if (self.finished) {
        self.finished();
    }
}
/// 开屏展现失败
- (void)adapter:(MEBaseAdapter *)adapter splashShowFailure:(NSError *)error {
    // 从数组中移除不需要处理的adapter
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.failed) {
        self.failed(error);
    }
}
/// 开屏被点击
- (void)adapterSplashClicked:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.clickBlock) {
        self.clickBlock();
    }
}
/// 开屏关闭事件
- (void)adapterSplashClose:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.closeBlock) {
        self.closeBlock();
    }
}

/// 广告被点击后,回到应用
- (void)adapterSplashDismiss:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    if (self.clickThenDismiss) {
        self.clickThenDismiss();
    }
}

// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShow:(NSString *)sceneId platform:(MEAdAgentType)platformType delay:(NSTimeInterval)delay bottomView:(UIView *)bottomView {
    NSArray <StrategyResultModel *>*resultArr = [[StrategyFactory sharedInstance] getPosidBySortTypeWithPlatform:platformType SceneId:sceneId];
    
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
            return [self assignAdPlatformAndShow:sceneId platform:nextPlatform delay:delay bottomView:bottomView];
        }
        
        adapter.splashDelegate = self;
        // 场景id
        adapter.sceneId = sceneId;
        adapter.isGetForCache = NO;
        adapter.sortType = [[MEConfigManager sharedInstance] getSortTypeFromSceneId:model.sceneId];
        [adapter showSplashWithPosid:model.posid delay:delay bottomView:bottomView];
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
