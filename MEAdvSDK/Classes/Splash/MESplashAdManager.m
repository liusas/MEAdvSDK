//
//  MESplashAdManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/27.
//

#import "MESplashAdManager.h"
#import "MEBUADAdapter.h"
#import "MEGDTAdapter.h"

#import "MEAdLogModel.h"

@interface MESplashAdManager ()<MEBaseAdapterSplashProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
@property (nonatomic, strong) MEBaseAdapter *currentAdapter;

@property (nonatomic, copy) LoadSplashAdFinished finished;
@property (nonatomic, copy) LoadSplashAdFailed failed;

// 成功回调的广告位数组
@property (nonatomic, strong) NSMutableArray *successPosidArr;

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
        self.currentAdapter = [[MEBaseAdapter alloc] init];
    }
    return self;
}

/// 展示开屏广告
- (void)showSplashAdvWithSceneId:(NSString *)sceneId
                        Finished:(LoadSplashAdFinished)finished
                          failed:(LoadSplashAdFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    // 置空以便重新分配
//    [self.currentAdapter removeFeedView];
    self.currentAdapter.splashDelegate = nil;
    self.currentAdapter = nil;
    
    // 分配广告平台
    if (![self assignAdPlatformAndShow:sceneId]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
    }
}

/// 停止开屏广告渲染,可能因为超时等原因
- (void)stopSplashRender {
    [self.currentAdapter stopSplashRender];
    self.currentAdapter = nil;
}

// MARK: - MEBaseAdapterSplashProtocol
/// 开屏展示成功
- (void)adapterSplashShowSuccess:(MEBaseAdapter *)adapter {
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
/// 开屏展现失败
- (void)adapter:(MEBaseAdapter *)adapter splashShowFailure:(NSError *)error {
    // 当前广告平台
    self.currentAdPlatform = adapter.platformType;
    
    MEAdLogModel *model = [MEAdLogModel new];
    model.network = self.configManger.dicPlatformTypeName[@(adapter.platformType)];
    model.posid = adapter.sceneId;
    model.pv = @"0";
    model.click = @"0";
    [MEAdLogModel saveLogModelToRealm:model];
    if (self.failed) {
        self.failed(error);
    }
}
/// 开屏被点击
- (void)adapterSplashClicked:(MEBaseAdapter *)adapter {
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
- (BOOL)assignAdPlatformAndShow:(NSString *)sceneId {
    // 先清空当前适配器
//    [self.currentAdapter stopCurrentVideo];
    self.currentAdapter = nil;
    
    // 显示开屏广告失败则重新分配广告平台
    // 按优先级选择合适的posid
    NSArray *posArr = [self.configManger getSplashPosidByOrderWithPlatform:MEAdAgentTypeNone sceneId:sceneId];
    
    if ([[MEConfigManager sharedInstance].GDTAPPId isEqualToString:kTestGDT_APPID] && [[MEConfigManager sharedInstance].BUADAPPId isEqualToString:kTestBUAD_APPID] && [[MEConfigManager sharedInstance].KSAppId isEqualToString:kTestKS_APPID]) {
        // 测试版本,只展示广点通广告
        posArr = @[@"9040714184494018", sceneId, @(MEAdAgentTypeGDT)];
    }
    
    if (posArr == nil) {
        // 如果没找到广告位, 则默认给穿山甲广告
        posArr = @[@"838537172", sceneId, @(MEAdAgentTypeBUAD)];
//        posArr = @[@"1070390225538460", sceneId, @(MEAdAgentTypeGDT)];
    }
    NSString *posid = posArr[0];
    
    // 获取相应的Adapter
    MEAdAgentType platformType = [posArr[2] integerValue];
    self.currentAdapter = [MEConfigManager getAdapterOfADPlatform:platformType];
    self.currentAdapter.splashDelegate = self;
    
    self.currentAdapter.sceneId = posArr[1];
    if (![self.currentAdapter showSplashWithPosid:posid]) {
        return [self assignAdPlatformAndShow:sceneId];
    }
    
    return YES;
}

@end
