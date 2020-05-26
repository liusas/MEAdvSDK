//
//  MEKSAdapter.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/4/9.
//

#import "MEKSAdapter.h"
#import <KSAdSDK/KSAdSDK.h>

@interface MEKSAdapter ()<KSRewardedVideoAdDelegate>

/// 激励视频对象
@property (nonatomic, strong) KSRewardedVideoAd *rewardedAd;
/// 判断激励视频是否能给奖励,每次关闭视频变false
@property (nonatomic, assign) BOOL isEarnRewarded;

/// 是否展示误点按钮
@property (nonatomic, assign) BOOL showFunnyBtn;
/// 是否需要展示
@property (nonatomic, assign) BOOL needShow;

@end

@implementation MEKSAdapter

// MARK: - override
+ (instancetype)sharedInstance {
    static MEKSAdapter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MEKSAdapter alloc] init];
    });
    return sharedInstance;
}

/// 添加广告参数
- (void)setAdParams:(NSDictionary *)dicParam {
    
}

/// 获取广告平台类型
- (MEAdAgentType)platformType{
    return MEAdAgentTypeKS;
}

// MARK: - 激励视频广告
- (BOOL)showRewardVideoWithPosid:(NSString *)posid {
    self.posid = posid;
    self.isEarnRewarded = false;
    
    if (![self topVC]) {
        return NO;
    }
    
    if (self.isTheVideoPlaying == YES) {
        // 若当前有视频正在播放,则此次激励视频不播放
        return YES;
    }
    
    if (!self.rewardedAd || self.rewardedAd.isValid == NO) {
        self.rewardedAd = nil;
        self.needShow = YES;
        self.rewardedAd = [[KSRewardedVideoAd alloc] initWithPosId:self.posid rewardedVideoModel:[KSRewardedVideoModel new]];
        self.rewardedAd.delegate = self;
        [self.rewardedAd loadAdData];
    } else {
        self.needShow = NO;
        [self.rewardedAd showAdFromRootViewController:[self topVC] showScene:@"" type:KSRewardedVideoAdRewardedTypeNormal];
    }
    
    return YES;
}

/// 结束当前视频
- (void)stopCurrentVideo {
    self.needShow = NO;
    if (self.rewardedAd.isValid) {
        UIViewController *topVC = [self topVC];
        [topVC dismissViewControllerAnimated:YES completion:nil];
//        self.rewardVideoAd = nil;
    }
}

#pragma mark - KSRewardedVideoAdDelegate
- (void)rewardedVideoAdDidLoad:(KSRewardedVideoAd *)rewardedVideoAd {
    // 这里表示广告素材已经准备好了,下面的代理rewardedVideoAdVideoDidLoad表示可以播放了
}

- (void)rewardedVideoAd:(KSRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    // 视频广告加载失败
    if (self.isTheVideoPlaying == NO && self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
        [self.videoDelegate adapter:self videoShowFailure:error];
    }
}

- (void)rewardedVideoAdVideoDidLoad:(KSRewardedVideoAd *)rewardedVideoAd {
    if (self.needShow) {
        if ([[self topVC] isKindOfClass:NSClassFromString(@"GDTWebViewController")]) {
            return;
        }
        if (rewardedVideoAd.isValid) {
            self.isTheVideoPlaying = YES;
            [self.rewardedAd showAdFromRootViewController:[self topVC]];
        }
    }
    // 这里能获取到ecpm
    NSInteger ecpm = rewardedVideoAd.ecpm;
    DLog(@"ecpm:%zd", (long)ecpm);
}

- (void)rewardedVideoAdWillVisible:(KSRewardedVideoAd *)rewardedVideoAd {
    // 视频即将播放
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoShowSuccess:)]) {
        [self.videoDelegate adapterVideoShowSuccess:self];
    }
}

- (void)rewardedVideoAdWillClose:(KSRewardedVideoAd *)rewardedVideoAd {
    self.isTheVideoPlaying = NO;
    self.needShow = NO;
    // 预加载
    [self.rewardedAd loadAdData];
    
    // 若没达到奖励条件,则不给回调
    if (self.isEarnRewarded == false) {
        return;
    }
    
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClose:)]) {
        [self.videoDelegate adapterVideoClose:self];
    }
    
    // 变回默认的不给奖励
    self.isEarnRewarded = false;
}

- (void)rewardedVideoAdDidClose:(KSRewardedVideoAd *)rewardedVideoAd {
}

- (void)rewardedVideoAdDidClick:(KSRewardedVideoAd *)rewardedVideoAd {
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClicked:)]) {
        [self.videoDelegate adapterVideoClicked:self];
    }
}

- (void)rewardedVideoAdDidClickSkip:(KSRewardedVideoAd *)rewardedVideoAd {
    // 点击了跳过, 则不给奖励
    self.isEarnRewarded = false;
}

- (void)rewardedVideoAd:(KSRewardedVideoAd *)rewardedVideoAd hasReward:(BOOL)hasReward {
    NSString *text = [NSString stringWithFormat:@"%@,是否有奖励:%@", NSStringFromSelector(_cmd), hasReward ? @"YES" : @"NO"];
    NSLog(@"%@", text);
    // 可以给收益
    self.isEarnRewarded = hasReward;
}

@end
