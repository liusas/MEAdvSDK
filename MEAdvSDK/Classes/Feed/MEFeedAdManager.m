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

@property (nonatomic, copy) LoadAdFinished loadFinished;
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

@property (nonatomic, assign) NSInteger loadAdsCount;

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
        self.loadAdsCount = 1;//默认 1 个
        _needToStop = NO;
    }
    return self;
}

// MARK: - 信息流
/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
- (void)loadFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
                        count:(NSInteger)count
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed {
    [self loadFeedViewWithWidth:feedWidth sceneId:sceneId count:count withDisplayTime:0 finished:finished failed:failed];
}

/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
/// @param displayTime 展示时长
- (void)loadFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
                        count:(NSInteger)count
              withDisplayTime:(NSTimeInterval)displayTime
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed {
    self.loadFinished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    self.currentViewWidth = feedWidth;
    
    if (self.loadAdsCount >= 1 && self.loadAdsCount <= 3) {
        self.loadAdsCount = count;
    } else {
        self.loadAdsCount = 1;
    }
    
    // 分配广告平台
    if (![self assignAdPlatformAndShowLogic1WithWidth:feedWidth count:count sceneId:sceneId platform:MEAdAgentTypeNone]) {
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
- (void)adapterFeedLoadSuccess:(MEBaseAdapter *)adapter feedViews:(NSArray *)feedViews {
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
    
    if (self.loadFinished) {
        self.loadFinished(feedViews);
    }
}

/// 展现FeedView成功
- (void)adapterFeedShowSuccess:(MEBaseAdapter *)adapter feedView:(UIView *)feedView {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.showFinished) {
        self.showFinished(feedView);
    }
}

/// 展现FeedView失败
- (void)adapter:(MEBaseAdapter *)adapter bannerShowFailure:(NSError *)error {
    // 从数组中移除不需要处理的adapter
    [self removeAssignResultArrObjectWithAdapter:adapter];
    
    if (self.hasSuccessfullyLoaded) {
        return;
    }
    
    _requestCount++;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 拉取次数小于2次,可以在广告拉取失败的同时再次拉取
    if (_requestCount < 2 && self.assignResultArr.count == 0 && !self.needToStop) {
        // 下次选择的广告平台
        MEAdAgentType nextPlatform = [self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType];

        CGFloat feedViewWidth = self.currentViewWidth ? self.currentViewWidth : [UIScreen mainScreen].bounds.size.width-40;
        [self assignAdPlatformAndShowLogic1WithWidth:feedViewWidth count:self.loadAdsCount sceneId:adapter.sceneId platform:nextPlatform];
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
- (BOOL)assignAdPlatformAndShowLogic1WithWidth:(CGFloat)width count:(NSInteger)count sceneId:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
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
            return [self assignAdPlatformAndShowLogic1WithWidth:width count:count sceneId:sceneId platform:nextPlatform];
        }
        
        adapter.feedDelegate = self;
        // 场景id
        adapter.sceneId = sceneId;
        adapter.isGetForCache = NO;
        adapter.sortType = [[MEConfigManager sharedInstance] getSortTypeFromSceneId:model.sceneId];
        [adapter showFeedViewWithWidth:width posId:model.posid count:count];
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
    log.st_t = AdLogAdType_Feed;
    log.so_t = sortType;
    log.posid = sceneId;
    log.network = [MEAdNetworkManager getNetworkNameFromAgentType:platformType];
    log.tk = [MEAdHelpTool stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", log.posid, log.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:log];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}


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
