//
//  MEInterstitialAdManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/12/13.
//

#import "MEInterstitialAdManager.h"
#import "MEBUADAdapter.h"
#import "MEGDTAdapter.h"

#import "MEAdLogModel.h"

@interface MEInterstitialAdManager ()<MEBaseAdapterInterstitialProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
@property (nonatomic, strong) MEBaseAdapter *currentAdapter;

@property (nonatomic, copy) LoadInterstitialAdFinished finished;
@property (nonatomic, copy) LoadInterstitialAdFailed failed;

@property (nonatomic, assign) NSInteger requestCount;

/// 是否展示误点按钮
@property (nonatomic, assign) BOOL showFunnyBtn;
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
        self.currentAdapter = [[MEBaseAdapter alloc] init];
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
    
    // 置空以便重新分配
    self.currentAdapter.interstitialDelegate = nil;
    self.currentAdapter = nil;
    
    self.showFunnyBtn = showFunnyBtn;
    // 分配广告平台
    if (![self assignAdPlatformAndShow:sceneId platform:MEAdAgentTypeNone]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
    }
}

// MARK: - MEBaseAdapterInterstitialProtocol
// 插屏广告加载成功
- (void)adapterInterstitialLoadSuccess:(MEBaseAdapter *)adapter {
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
    
    if (self.finished) {
        self.finished();
    }
}

// 插屏广告加载失败
- (void)adapter:(MEBaseAdapter *)adapter interstitialLoadFailure:(NSError *)error {
    _requestCount++;
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    // 拉取次数小于2次,可以在广告拉取失败的同时再次拉取
    if (_requestCount < 2) {
        // 下次选择的广告平台
        [self assignAdPlatformAndShow:adapter.sceneId platform:[self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType]];
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

// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShow:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
    self.currentAdapter = nil;
    
    // 按优先级选择合适的posid
    NSArray *posArr = [self.configManger getInterstitialPosidByOrderWithPlatform:targetPlatform sceneId:sceneId];
    
    if ([[MEConfigManager sharedInstance].GDTAPPId isEqualToString:kTestGDT_APPID] && [[MEConfigManager sharedInstance].BUADAPPId isEqualToString:kTestBUAD_APPID] && [[MEConfigManager sharedInstance].KSAppId isEqualToString:kTestKS_APPID]) {
        // 测试版本,只展示广点通广告
        posArr = @[kTestGDT_Interstitial, sceneId, @(MEAdAgentTypeGDT)];
    }
    
    if (posArr == nil) {
        return NO;
    }
    
    NSString *posid = posArr[0];
    
    // 获取相应的Adapter
    MEAdAgentType platformType = [posArr[2] integerValue];
    self.currentAdapter = [MEConfigManager getAdapterOfADPlatform:platformType];
    self.currentAdapter.interstitialDelegate = self;
    
    self.currentAdapter.sceneId = posArr[1];
    if (![self.currentAdapter showInterstitialViewWithPosid:posid showFunnyBtn:self.showFunnyBtn]) {
        return [self assignAdPlatformAndShow:sceneId platform:MEAdAgentTypeNone];
    }
    
    return YES;
}

@end
