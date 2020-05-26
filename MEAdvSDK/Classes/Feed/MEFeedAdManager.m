//
//  MEFeedAdManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/8.
//

#import "MEFeedAdManager.h"
#import "MEBUADAdapter.h"
#import "MEGDTAdapter.h"
#import "MEGDTFeedRenderAdapter.h"
#import <UIKit/UIKit.h>

#import "MEAdLogModel.h"
#import "MEAdMemoryCache.h"

#import <BUAdSDK/BUNativeExpressAdView.h>
#import <GDTNativeExpressAdView.h>
#import "MEGDTCustomView.h"

@interface MEFeedAdManager ()<MEBaseAdapterFeedProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
@property (nonatomic, strong) MEBaseAdapter *currentAdapter;

@property (nonatomic, copy) CacheLoadAdFinished cacheLoadFinished;
@property (nonatomic, copy) CacheLoadAdFailed cacheLoadFailed;
@property (nonatomic, copy) LoadAdFinished finished;
@property (nonatomic, copy) LoadAdFailed failed;

@property (nonatomic, strong) MEAdMemoryCache *adCache;

// 成功回调的广告位数组
@property (nonatomic, strong) NSMutableArray *successPosidArr;
// 信息流视图的宽度
@property (nonatomic, assign) CGFloat currentViewWidth;
// 记录广告拉取失败后,重新拉取的次数
@property (nonatomic, assign) NSInteger requestCount;

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
        self.currentAdapter = [[MEBaseAdapter alloc] init];
        self.adCache = [[MEAdMemoryCache alloc] init];
    }
    return self;
}

// MARK: - 信息流
/// 拉取信息流广告到缓存
/// @param feedWidth 信息流宽度
/// @param sceneId 场景id
- (void)saveFeedCacheWithWidth:(CGFloat)feedWidth
                       sceneId:(NSString *)sceneId
                      finished:(CacheLoadAdFinished)finished
                        failed:(CacheLoadAdFailed)failed {
    self.cacheLoadFinished = finished;
    self.cacheLoadFailed = failed;
    
    // 分配广告平台
    [self assignAdPlatformForCacheWithWidth:feedWidth sceneId:sceneId];
}

/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
/// @param size 广告位大小
- (void)showFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed {
    [self showFeedViewWithWidth:feedWidth sceneId:sceneId withDisplayTime:0 finished:finished failed:failed];
}

/// 显示信息流视图
/// @param feedWidth 信息流背景视图宽度
/// @param size 广告位大小
/// @param displayTime 展示时长
- (void)showFeedViewWithWidth:(CGFloat)feedWidth
                      sceneId:(NSString *)sceneId
              withDisplayTime:(NSTimeInterval)displayTime
                     finished:(LoadAdFinished)finished
                       failed:(LoadAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    // 置空以便重新分配
    [self.currentAdapter removeFeedView];
    self.currentAdapter.feedDelegate = nil;
    self.currentAdapter = nil;
    
    self.currentViewWidth = feedWidth;
    
    // 分配广告平台
    if (![self assignAdPlatformAndShowLogic1WithWidth:feedWidth sceneId:sceneId platform:MEAdAgentTypeNone]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
    }
}

/// 移除信息流视图
- (void)removeFeedView {
    [self.currentAdapter removeFeedView];
    self.currentAdapter = nil;
}

// MARK: - 信息流自渲染
/// 信息流预加载,并存入缓存
/// @param feedWidth 信息流宽度
/// @param posId 广告位id
- (void)saveRenderFeedCacheWithSceneId:(NSString *)sceneId
                              finished:(CacheLoadAdFinished)finished
                                failed:(CacheLoadAdFailed)failed {
    self.cacheLoadFinished = finished;
    self.cacheLoadFailed = failed;
    
    // 分配广告平台
    [self assignRenderAdPlatformForCacheWithSceneId:sceneId];
}

/// 显示自渲染的信息流视图
- (BOOL)showRenderFeedViewWithSceneId:(NSString *)sceneId
                             finished:(LoadAdFinished)finished
                               failed:(LoadAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    // 置空以便重新分配
    [self.currentAdapter removeFeedView];
    self.currentAdapter.feedDelegate = nil;
    self.currentAdapter = nil;
    
    // 分配广告平台
    if (![self assignRenderAdPlatformAndShowWithSceneId:sceneId platform:MEAdAgentTypeNone]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
    }
    return YES;
}

/// 移除自渲染信息流视图
- (void)removeRenderFeedView {
    [self.currentAdapter removeFeedView];
    self.currentAdapter = nil;
}

// MARK: - MEBaseAdapterFeedProtocol
/// 信息流缓存广告拉取成功的回调
- (void)adapterFeedCacheGetSuccess:(MEBaseAdapter *)adapter feedViews:(NSArray<UIView *> *)feedViews {
    // 当前广告平台
    NSString *selectSceneId = [self.configManger sceneIdExchangedBuadPosid:adapter.sceneId];
    self.currentAdPlatform = adapter.platformType;
    if (adapter.platformType == MEAdAgentTypeBUAD) {
        [feedViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BUNativeExpressAdView *expressView = (BUNativeExpressAdView *)obj;
            [self.adCache setObject:expressView forSceneId:selectSceneId posId:adapter.posid platformType:adapter.platformType];
        }];
    } else if (adapter.platformType == MEAdAgentTypeGDT) {
        [feedViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIView *expressView = nil;
            if ([obj isKindOfClass:[MEGDTCustomView class]]) {
                expressView = (MEGDTCustomView *)obj;
            } else {
                expressView = (GDTNativeExpressAdView *)obj;
            }
            [self.adCache setObject:expressView forSceneId:selectSceneId posId:adapter.posid platformType:adapter.platformType];
        }];
    }
    
    if (self.cacheLoadFinished) {
        self.cacheLoadFinished();
    }
}

/// 信息流缓存广告拉取失败的回调
- (void)adapterFeedCacheGetFailed:(NSError *)error {
    if (self.cacheLoadFailed) {
        self.cacheLoadFailed(error);
    }
}

/// 展现FeedView成功
- (void)adapterFeedShowSuccess:(MEBaseAdapter *)adapter feedView:(nonnull UIView *)feedView {
    // 拉取成功后,置0
    _requestCount = 0;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    MEAdLogModel *model = [MEAdLogModel new];
    model.network = self.configManger.dicPlatformTypeName[@(adapter.platformType)];;
    model.posid = adapter.sceneId;
    model.pv = @"1";
    model.click = @"0";
    [MEAdLogModel saveLogModelToRealm:model];
    
    // 控制广告平台展示频次
    [self.configManger changeAdFrequencyWithSceneId:adapter.sceneId];
    // 再次缓存
    [self saveFeedCacheWithWidth:feedView.frame.size.width sceneId:adapter.sceneId finished:nil failed:nil];
    
    if (self.finished) {
        self.finished(feedView);
    }
}

- (void)adapterFeedRenderShowSuccess:(MEBaseAdapter *)adapter feedView:(GDTUnifiedNativeAdView *)feedView {
    // 拉取成功后,置0
    _requestCount = 0;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    MEAdLogModel *model = [MEAdLogModel new];
    model.network = self.configManger.dicPlatformTypeName[@(adapter.platformType)];
    model.posid = adapter.sceneId;
    model.pv = @"1";
    model.click = @"0";
    [MEAdLogModel saveLogModelToRealm:model];
    
    // 控制广告平台展示频次
    [self.configManger changeAdFrequencyWithSceneId:adapter.sceneId];
    // 再次缓存
    [self saveRenderFeedCacheWithSceneId:adapter.sceneId finished:nil failed:nil];
    
    if (self.finished) {
        self.finished(feedView);
    }
}

/// 展现FeedView失败
- (void)adapter:(MEBaseAdapter *)adapter bannerShowFailure:(NSError *)error {
    _requestCount++;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 拉取次数小于2次,可以在广告拉取失败的同时再次拉取
    if (_requestCount < 2) {
        // 下次选择的广告平台
        MEAdAgentType nextPlatform = [self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType];

        // 自渲染信息流加载失败则再次加载自渲染信息流
        if ([adapter isKindOfClass:[MEGDTFeedRenderAdapter class]]) {
            [self assignRenderAdPlatformAndShowWithSceneId:adapter.sceneId platform:MEAdAgentTypeGDT];
            return;
        }

        if (self.currentViewWidth != 0) {
            [self assignAdPlatformAndShowLogic1WithWidth:self.currentViewWidth sceneId:adapter.sceneId platform:nextPlatform];
        } else {
            [self assignAdPlatformAndShowLogic1WithWidth:[UIScreen mainScreen].bounds.size.width-40 sceneId:adapter.sceneId platform:nextPlatform];
        }
        return;
    }
    
    MEAdLogModel *model = [MEAdLogModel new];
    model.network = self.configManger.dicPlatformTypeName[@(adapter.platformType)];
    model.posid = adapter.sceneId;
    model.pv = @"0";
    model.click = @"0";
    [MEAdLogModel saveLogModelToRealm:model];
    
    _requestCount = 0;
    if (self.failed) {
        self.failed(error);
    }
}

/// 关闭了信息流广告
- (void)adapterFeedClose:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    if (self.closeBlock) {
        self.closeBlock();
    }
}

/// FeedView被点击
- (void)adapterFeedClicked:(MEBaseAdapter *)adapter {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    MEAdLogModel *model = [MEAdLogModel new];
    model.network = self.configManger.dicPlatformTypeName[@(adapter.platformType)];
    model.posid = adapter.sceneId;
    model.pv = @"0";
    model.click = @"1";
    [MEAdLogModel saveLogModelToRealm:model];
    
    if (self.clickBlock) {
        self.clickBlock();
    }
}

// MARK: - Private
// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShowLogic1WithWidth:(CGFloat)width sceneId:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
    // 先清空当前适配器
    [self.currentAdapter removeFeedView];
    self.currentAdapter = nil;
    
    // 显示FeedView失败则重新分配广告平台
    // 按优先级选择合适的posid
    NSArray *posArr = [self.configManger getFeedPosidByOrderWithPlatform:targetPlatform SceneId:sceneId];
    
    if ([[MEConfigManager sharedInstance].GDTAPPId isEqualToString:kTestGDT_APPID] && [[MEConfigManager sharedInstance].BUADAPPId isEqualToString:kTestBUAD_APPID] && [[MEConfigManager sharedInstance].KSAppId isEqualToString:kTestKS_APPID]) {
        // 测试版本,只展示广点通广告
        posArr = @[kTestGDT_FeedView, sceneId, @(MEAdAgentTypeGDT)];
    }
    
    if (posArr == nil) {
        // 表示该位置没有分配到广告位,走广告位分配失败回调
        return NO;
    }
    
    // 经过筛选后的场景id,基本上都是传来的参数sceneId,也有可能是默认的场景id
    NSString *selectSceneId = [self.configManger sceneIdExchangedBuadPosid:sceneId];
    NSString *posid = posArr[0];
    // 获取相应的Adapter,广告平台
    MEAdAgentType platformType = [posArr[2] integerValue];
    // 1. 先判断缓存中是否有未失效的广告
    if ([self.adCache containsObjectWithSceneId:selectSceneId posId:posid platformType:platformType]) {
        // 2.1 有则直接回调成功成功的view
        if (platformType == MEAdAgentTypeBUAD) {
            BUNativeExpressAdView *adView = [self.adCache objectForSceneId:selectSceneId posId:posid platformType:platformType];
            if (adView != nil) {
                // 将缓存中的广告取出并再次拉取新广告存入缓存
                MEBUADAdapter *adapter = [MEBUADAdapter new];
                adapter.sceneId = sceneId;
                [self adapterFeedShowSuccess:adapter feedView:adView];
                return YES;
            }
        } else if (platformType == MEAdAgentTypeGDT) {
            GDTNativeExpressAdView *adView = [self.adCache objectForSceneId:selectSceneId posId:posid platformType:platformType];
            if (adView != nil) {
                // 将缓存中的广告取出并再次拉取新广告存入缓存
                MEGDTAdapter *adapter = [MEGDTAdapter new];
                adapter.sceneId = sceneId;
                [self adapterFeedShowSuccess:adapter feedView:adView];
                return YES;
            }
        }
    }
    
    // 2.2 没有则重新拉取
    // 广告位id
    self.currentAdapter = [MEConfigManager getAdapterOfADPlatform:platformType];
    self.currentAdapter.feedDelegate = self;
    // 场景id
    self.currentAdapter.sceneId = posArr[1];
    self.currentAdapter.isGetForCache = NO;
    if (![self.currentAdapter showFeedViewWithWidth:width posId:posid]) {
        return [self assignAdPlatformAndShowLogic1WithWidth:width sceneId:sceneId platform:MEAdAgentTypeNone];
    }
    
    return YES;
}

- (void)assignAdPlatformForCacheWithWidth:(CGFloat)width sceneId:(NSString *)sceneId {
    self.currentAdapter = nil;
    
    // 显示FeedView失败则重新分配广告平台
    // 按优先级选择合适的posid
    NSArray *posArr = [self.configManger getFeedPosidByOrderWithPlatform:MEAdAgentTypeNone SceneId:sceneId];
    
    if (posArr == nil) {
        // 表示该位置没有分配到广告位,走广告位分配失败回调
        return;
    }
    
    // 经过筛选后的场景id,基本上都是传来的参数sceneId,也有可能是默认的场景id
    NSString *selectSceneId = [self.configManger sceneIdExchangedBuadPosid:sceneId];
    NSString *posid = posArr[0];
    // 获取相应的Adapter,广告平台
    MEAdAgentType platformType = [posArr[2] integerValue];
    // 判断缓存中是否有未失效且没被使用的广告
    if ([self.adCache containsObjectWithSceneId:selectSceneId posId:posid platformType:platformType]) {
        if (self.cacheLoadFinished) {
            self.cacheLoadFinished();
        }
        return;
    }
    
    // 2.2 没有则重新拉取
    // 广告位id
    self.currentAdapter = [MEConfigManager getAdapterOfADPlatform:platformType];
    self.currentAdapter.feedDelegate = self;
    self.currentAdapter.isGetForCache = YES;
    // 场景id
    self.currentAdapter.sceneId = posArr[1];
    [self.currentAdapter saveFeedCacheWithWidth:width posId:posid];
    
    return;
}

/// 为自渲染信息流分配平台
- (BOOL)assignRenderAdPlatformAndShowWithSceneId:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
    // 先清空当前适配器
    [self.currentAdapter removeFeedView];
    self.currentAdapter = nil;
    
    // 显示FeedView失败则重新分配广告平台
    // 按优先级选择合适的posid
    NSArray *posArr = [self.configManger getFeedPosidByOrderWithPlatform:targetPlatform SceneId:sceneId];
    
    if (posArr == nil) {
        // 表示该位置没有分配到广告位,走广告位分配失败回调
        return NO;
    }
    
    // 经过筛选后的场景id,基本上都是传来的参数sceneId,也有可能是默认的场景id
    NSString *selectSceneId = [self.configManger sceneIdExchangedBuadPosid:sceneId];
    NSString *posid = posArr[0];
    // 获取相应的Adapter,广告平台
    MEAdAgentType platformType = [posArr[2] integerValue];

    // 1. 先判断缓存中是否有未失效的广告
    if ([self.adCache containsObjectWithSceneId:selectSceneId posId:posid platformType:platformType]) {
        // 2.1 有则直接回调成功成功的view
        if (platformType == MEAdAgentTypeGDT) {
            MEGDTCustomView *adView = [self.adCache objectForSceneId:selectSceneId posId:posid platformType:platformType];
            if (adView != nil) {
                // 将缓存中的广告取出并再次拉取新广告存入缓存
                MEGDTFeedRenderAdapter *adapter = [MEGDTFeedRenderAdapter new];
                adapter.sceneId = sceneId;
                [self adapterFeedRenderShowSuccess:adapter feedView:adView];
                return YES;
            }
        }
    }

    // 2.2 没有则重新拉取
    // 广告位id
    self.currentAdapter = [MEConfigManager getAdapterByPlatform:platformType andAdType:MEAdType_Render_Feed];
//    self.currentAdapter = [[MEGDTFeedRenderAdapter alloc] init];
    self.currentAdapter.feedDelegate = self;
    // 场景id
    if (![self.currentAdapter isKindOfClass:[MEGDTFeedRenderAdapter class]]) {
        // 若配置文件出错,默认出2048051自渲染的广告
        posid = @"6010690730057022";
        self.currentAdapter.sceneId = @"2048051";
    } else {
        self.currentAdapter.sceneId = posArr[1];
    }
    self.currentAdapter.isGetForCache = NO;
    if (![self.currentAdapter showRenderFeedViewWithPosId:posid]) {
        return [self assignRenderAdPlatformAndShowWithSceneId:sceneId platform:MEAdAgentTypeNone];
    }
    
    return YES;
}

- (void)assignRenderAdPlatformForCacheWithSceneId:(NSString *)sceneId {
    self.currentAdapter = nil;
    
    // 显示FeedView失败则重新分配广告平台
    // 按优先级选择合适的posid
    NSArray *posArr = [self.configManger getFeedPosidByOrderWithPlatform:MEAdAgentTypeNone SceneId:sceneId];
    
    if (posArr == nil) {
        // 表示该位置没有分配到广告位,走广告位分配失败回调
        return;
    }
    
    // 经过筛选后的场景id,基本上都是传来的参数sceneId,也有可能是默认的场景id
    NSString *selectSceneId = [self.configManger sceneIdExchangedBuadPosid:sceneId];
    NSString *posid = posArr[0];
    // 获取相应的Adapter,广告平台
    MEAdAgentType platformType = [posArr[2] integerValue];
    // 判断缓存中是否有未失效且没被使用的广告
    if ([self.adCache containsObjectWithSceneId:selectSceneId posId:posid platformType:platformType]) {
        if (self.cacheLoadFinished) {
            self.cacheLoadFinished();
        }
        return;
    }
    
    // 2.2 没有则重新拉取
    // 广告位id
    self.currentAdapter = [MEConfigManager getAdapterByPlatform:platformType andAdType:MEAdType_Render_Feed];
    self.currentAdapter.feedDelegate = self;
    self.currentAdapter.isGetForCache = YES;
    // 场景id
    self.currentAdapter.sceneId = posArr[1];
    [self.currentAdapter saveRenderFeedCacheWithPosId:posid];
    
    return;
}

@end
