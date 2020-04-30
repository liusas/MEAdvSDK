//
//  MERewardedVideoManager.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/8.
//

#import "MERewardedVideoManager.h"
#import "MEConfigManager.h"
#import "MEBUADAdapter.h"
#import "MEGDTAdapter.h"
#import "MEAdLogModel.h"

@interface MERewardedVideoManager ()<MEBaseAdapterVideoProtocol>

@property (nonatomic, strong) MEConfigManager *configManger;
@property (nonatomic, strong) MEBaseAdapter *currentAdapter;

@property (nonatomic, copy) LoadRewardVideoFinish finished;
@property (nonatomic, copy) LoadRewardVideoFailed failed;

@property (nonatomic, assign) NSInteger requestCount;

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
        self.currentAdapter = [[MEBaseAdapter alloc] init];
    }
    return self;
}
/// 展示激励视频
- (void)showRewardVideoWithSceneId:(NSString *)sceneId
                          Finished:(LoadRewardVideoFinish)finished
                            failed:(LoadRewardVideoFailed)failed {
    self.finished = finished;
    self.failed = failed;
    
    _requestCount = 0;
    
    if (self.currentAdapter.isTheVideoPlaying == YES) {
        // 若当前正在播放视频,则禁止此次操作
        return;
    }
    
    // 置空以便重新分配
    [self.currentAdapter stopCurrentVideo];
    self.currentAdapter.videoDelegate = nil;
    self.currentAdapter = nil;
    // 分配广告平台
    if (![self assignAdPlatformAndShowLogic1WithSceneId:sceneId platform:MEAdAgentTypeNone]) {
        NSError *error = [NSError errorWithDomain:@"adv assign failed" code:0 userInfo:@{NSLocalizedDescriptionKey: @"分配失败"}];
        failed(error);
    }
}

/// 关闭当前视频
- (void)stopCurrentVideo {
    [self.currentAdapter stopCurrentVideo];
    self.currentAdapter = nil;
}

// MARK: - MEBaseAdapterVideoProtocol
/// 展现video成功
- (void)adapterVideoShowSuccess:(MEBaseAdapter *)adapter {
    // 拉取成功后,置0
    _requestCount = 0;
    
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

/// 展现video失败
- (void)adapter:(MEBaseAdapter *)adapter videoShowFailure:(NSError *)error {
    _requestCount++;
    
    // 拉取次数小于2次,可以在广告拉取失败的同时再次拉取
    if (_requestCount < 2) {
        // 下次选择的广告平台
        [self assignAdPlatformAndShowLogic1WithSceneId:adapter.sceneId platform:[self.configManger nextAdPlatformWithSceneId:adapter.sceneId currentPlatform:adapter.platformType]];
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

/// 视频广告播放完毕
- (void)adapterVideoFinishPlay:(MEBaseAdapter *)adapter {
    if (self.finishPlayBlock) {
        self.finishPlayBlock();
    }
}

/// video被点击
- (void)adapterVideoClicked:(MEBaseAdapter *)adapter {
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

/// video关闭事件
- (void)adapterVideoClose:(MEBaseAdapter *)adapter {
    if (self.closeBlock) {
        self.closeBlock();
    }
}

// MARK: - Private
// MARK: 按广告位posid选择广告的逻辑,此次采用
- (BOOL)assignAdPlatformAndShowLogic1WithSceneId:(NSString *)sceneId platform:(MEAdAgentType)targetPlatform {
    // 先清空当前适配器
    [self.currentAdapter stopCurrentVideo];
    self.currentAdapter = nil;
    
    // 显示RewardedVideo失败则重新分配广告平台
    // 按优先级选择合适的posid
    NSArray *posArr = [self.configManger getRewardVideoPosidByOrderWithPlatform:targetPlatform sceneId:sceneId];
    
    if (posArr == nil) {
        return NO;
    }
    
    NSString *posid = posArr[0];
    
    // 获取相应的Adapter
    MEAdAgentType platformType = [posArr[2] integerValue];
//    platformType = MEAdAgentTypeAdmob;
    self.currentAdapter = [MEConfigManager getAdapterOfADPlatform:platformType];
    self.currentAdapter.videoDelegate = self;
    
    self.currentAdapter.sceneId = posArr[1];
    if (![self.currentAdapter showRewardVideoWithPosid:posid]) {
        return [self assignAdPlatformAndShowLogic1WithSceneId:sceneId platform:MEAdAgentTypeNone];
    }
    
    return YES;
}

@end
