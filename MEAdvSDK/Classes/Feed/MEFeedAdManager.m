//
//  MEFeedAdManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/8.
//

#import "MEFeedAdManager.h"
#import <UIKit/UIKit.h>
#import "MEAdNetworkManager.h"
#import "MEAdMemoryCache.h"
#import "StrategyFactory.h"
#import "MEExpirationTimer.h"
#import "MEBaseAdapter.h"

//#import <BUAdSDK/BUNativeExpressAdView.h>
//#import <GDTNativeExpressAdView.h>
//#import "MEGDTCustomView.h"

@interface MEFeedAdManager ()<MEBaseAdapterFeedProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
/// sceneId:adapter,记录当前展示广告的adapter
@property (nonatomic, strong) NSMutableDictionary <NSString *, id<MEBaseAdapterProtocol>>*currentAdapters;
/// 此次信息流管理类分配到的广告平台模型数组,保证一次信息流广告有一个广告平台成功展示
@property (nonatomic, strong) NSMutableArray <StrategyResultModel *>*assignResultArr;

@property (nonatomic, copy) CacheLoadAdFinished cacheLoadFinished;
@property (nonatomic, copy) CacheLoadAdFailed cacheLoadFailed;
@property (nonatomic, copy) LoadAdFinished finished;
@property (nonatomic, copy) LoadAdFailed failed;

@property (nonatomic, strong) MEAdMemoryCache *adCache;

// 信息流视图的宽度
@property (nonatomic, assign) CGFloat currentViewWidth;
// 记录广告拉取失败后,重新拉取的次数
@property (nonatomic, assign) NSInteger requestCount;

// 只允许回调一次加载成功事件
@property (nonatomic, assign) BOOL hasSuccessfullyLoaded;
// 超时计时器
@property (nonatomic, strong) MEExpirationTimer *expirationTimer;

// 广告应该停止请求,可能原因1.超时, 2.已经成功拉取到广告
@property (nonatomic, assign) BOOL needToStop;

@end

@implementation MEFeedAdManager

+ (instancetype)shareInstance {
    static MEFeedAdManager *feedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        feedManager = [[MEFeedAdManager alloc] init];
    });
    return feedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.configManger = [MEConfigManager sharedInstance];
        self.currentAdapters = [NSMutableDictionary dictionary];
        self.assignResultArr = [NSMutableArray array];
        self.adCache = [[MEAdMemoryCache alloc] init];
        _needToStop = NO;
    }
    return self;
}

// MARK: - 信息流
/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
- (void)showFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed {
    [self showFeedViewWithWidth:feedWidth sceneId:sceneId withDisplayTime:0 finished:finished failed:failed];
}

/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
/// @param displayTime 展示时长
- (void)showFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
              withDisplayTime:(NSTimeInterval)displayTime
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    self.currentViewWidth = feedWidth;
    
    // 分配广告平台
    if (![self assignAdPlatformAndShowLogic1WithWidth:feedWidth sceneId:sceneId platform:MEAdAgentTypeNone]) {
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

// MARK: - 信息流自渲染
/// 显示自渲染的信息流视图
- (void)showRenderFeedViewWithSceneId:(NSString *)sceneId
                             finished:(LoadAdFinished)finished
                               failed:(LoadAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    // 分配广告平台
    if (![self assignRenderAdPlatformAndShowWithSceneId:sceneId platform:MEAdAgentTypeNone]) {
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

// MARK: - MEBaseAdapterFeedProtocol
/// 展现FeedView成功
- (void)adapterFeedShowSuccess:(MEBaseAdapter *)adapter feedView:(nonnull UIView *)feedView {
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
    
    // 拉取成功后,置0
    _requestCount = 0;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 控制广告平台展示频次
    [StrategyFactory changeAdFrequencyWithSceneId:adapter.sceneId];
    
    if (self.finished) {
        self.finished(feedView);
    }
}

- (void)adapterFeedRenderShowSuccess:(MEBaseAdapter *)adapter feedView:(GDTUnifiedNativeAdView *)feedView {
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
    
    // 拉取成功后,置0
    _requestCount = 0;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 添加adapter到当前管理adapter的字典
    self.currentAdapters[adapter.sceneId] = adapter;
    
    // 控制广告平台展示频次
    [StrategyFactory changeAdFrequencyWithSceneId:adapter.sceneId];
    
    if (self.finished) {
        self.finished(feedView);
    }
}

/// 展现FeedView失败
- (void)adapter:(MEBaseAdapter *)adapter bannerShowFailure:(NSError *)error {
    // 从数组中移除不需要处理的adapter
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    _requestCount++;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 拉取次数小于2次,可以在广告拉取失败的同时再次拉取
    if (_requestCount < 2 && self.assignResultArr.count == 0 && !self.needToStop) {
        // 下次选择的广告平台
        MEAdAgentType nextPlatform = [self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType];

        // 自渲染信息流加载失败则再次加载自渲染信息流
#warning 去掉广点通时隐藏的
//        if ([adapter isKindOfClass:[MEGDTFeedRenderAdapter class]]) {
//            [self assignRenderAdPlatformAndShowWithSceneId:adapter.sceneId platform:MEAdAgentTypeGDT];
//            return;
//        }

        CGFloat feedViewWidth = self.currentViewWidth ? self.currentViewWidth : [UIScreen mainScreen].bounds.size.width-40;
        [self assignAdPlatformAndShowLogic1WithWidth:feedViewWidth sceneId:adapter.sceneId platform:nextPlatform];
        return;
    }
    
    _requestCount = 0;
    if (self.failed) {
        self.failed(error);
    }
}

/// 关闭了信息流广告
- (void)adapterFeedClose:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    [self.currentAdapters removeObjectForKey:adapter.sceneId];
    
    if (self.closeBlock) {
        self.closeBlock();
    }
}

/// FeedView被点击
- (void)adapterFeedClicked:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.clickBlock) {
        self.clickBlock();
    }
}

// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShowLogic1WithWidth:(CGFloat)width sceneId:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
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
        
        // 若此时adapter依然为空,则表示没有相应广告平台的适配器
        // 若策略是每次只请求一个广告平台,则继续找下一个广告平台
        if (adapter == nil && resultArr.count == 1) {
            MEAdAgentType nextPlatform = [self.configManger nextAdPlatformWithSceneId:sceneId currentPlatform:model.platformType];
            if (nextPlatform == MEAdAgentTypeAll) {
                // 没有分配到合适广告
                return NO;
            }
            
            // 找到下一个广告平台则指定出这个平台的广告
            return [self assignAdPlatformAndShowLogic1WithWidth:width sceneId:sceneId platform:nextPlatform];
        }
        
        adapter.feedDelegate = self;
        // 场景id
        adapter.sceneId = sceneId;
        adapter.isGetForCache = NO;
        adapter.sortType = [[MEConfigManager sharedInstance] getSortTypeFromSceneId:model.sceneId];
        [adapter showFeedViewWithWidth:width posId:model.posid];
    }
    
    return YES;
}

/// 为自渲染信息流分配平台
- (BOOL)assignRenderAdPlatformAndShowWithSceneId:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
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
        
        // 若此时adapter依然为空,则表示没有相应广告平台的适配器
        // 若策略是每次只请求一个广告平台,则继续找下一个广告平台
        if (adapter == nil && resultArr.count == 1) {
            MEAdAgentType nextPlatform = [self.configManger nextAdPlatformWithSceneId:sceneId currentPlatform:model.platformType];
            if (nextPlatform == MEAdAgentTypeAll) {
                // 没有分配到合适广告
                return NO;
            }
            
            // 找到下一个广告平台则指定出这个平台的广告
            return [self assignRenderAdPlatformAndShowWithSceneId:sceneId platform:nextPlatform];
        }
        
        adapter.feedDelegate = self;
        // 场景id
        adapter.sceneId = sceneId;
        adapter.isGetForCache = NO;
        adapter.sortType = [[MEConfigManager sharedInstance] getSortTypeFromSceneId:model.sceneId];
        [adapter showRenderFeedViewWithPosId:model.posid];
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
        if ([adapter respondsToSelector:@selector(removeFeedViewWithPosid:)]) {
            [adapter removeFeedViewWithPosid:model.posid];
        }
        if ([adapter respondsToSelector:@selector(removeRenderFeedViewWithPosid:)]) {
            [adapter removeRenderFeedViewWithPosid:model.posid];
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
