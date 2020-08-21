//
//  MobiRewardedVideo.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import "MobiRewardedVideo.h"
#import "MobiRewardedVideoAdManager.h"
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"
#import "MobiRewardedVideoError.h"
#import "MobiRewardedVideoModel.h"


static MobiRewardedVideo *gSharedInstance = nil;

@interface MobiRewardedVideo ()<MobiRewardedVideoAdManagerDelegate>

@property (nonatomic, strong) NSMutableDictionary *rewardedVideoAdManagers;
/// 存放不同posid对应的delegate
@property (nonatomic, strong) NSMapTable<NSString *, id<MobiRewardedVideoDelegate>> * delegateTable;

+ (MobiRewardedVideo *)sharedInstance;

@end

@implementation MobiRewardedVideo

- (instancetype)init {
    if (self = [super init]) {
        _rewardedVideoAdManagers = [[NSMutableDictionary alloc] init];

        // Keys (ad unit ID) are strong, values (delegates) are weak.
        _delegateTable = [NSMapTable strongToWeakObjectsMapTable];
    }

    return self;
}

/// 设置用来接收posid对应的激励视频回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiRewardedVideoDelegate>)delegate forPosid:(NSString *)posid {
    if (posid == nil) {
        return;
    }
    
    [[[self class] sharedInstance].delegateTable setObject:delegate forKey:posid];
}

/// 从有效的posid中删除对应的接收激励视频回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiRewardedVideoDelegate>)delegate {
    if (delegate == nil) {
        return;
    }

    NSMapTable * mapTable = [[self class] sharedInstance].delegateTable;

    NSMutableArray<NSString *> * keys = [NSMutableArray array];
    for (NSString * key in mapTable) {
        if ([mapTable objectForKey:key] == delegate) {
            [keys addObject:key];
        }
    }

    for (NSString * key in keys) {
        [mapTable removeObjectForKey:key];
    }
}

/// 删除posid对应的delegate
/// @param posid 广告位id
+ (void)removeDelegateForPosid:(NSString *)posid {
    if (posid == nil) {
        return;
    }

    [[[self class] sharedInstance].delegateTable removeObjectForKey:posid];
}

/// 加载激励视频广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid, reward, rewardAmount等),可为nil
+ (void)loadRewardedVideoAdWithPosid:(NSString *)posid rewardedVideoModel:(MobiRewardedVideoModel *)model {
    MobiRewardedVideo *sharedInstance = [[self class] sharedInstance];
    
    if (![posid length]) {
        NSError *error = [NSError errorWithDomain:MobiRewardedVideoAdsSDKDomain code:MobiRewardedVideoAdErrorInvalidPosid userInfo:nil];
        id<MobiRewardedVideoDelegate> delegate = [sharedInstance.delegateTable objectForKey:posid];
        [delegate rewardedVideoAdDidFailToLoad:sharedInstance error:error];
        return;
    }
    
    if (model != nil) {
        sharedInstance.rewardedVideoModel = model;
    }
    sharedInstance.posid = posid;
    
    MobiRewardedVideoAdManager *adManager = sharedInstance.rewardedVideoAdManagers[posid];

    if (!adManager) {
        adManager = [[MobiRewardedVideoAdManager alloc] initWithPosid:posid delegate:sharedInstance];
        sharedInstance.rewardedVideoAdManagers[posid] = adManager;
    }

    // 广告目标锁定,都是便于更精准的投放广告
    MobiAdTargeting *targeting = [MobiAdTargeting targetingWithCreativeSafeSize:MPApplicationFrame(YES).size];
    targeting.keywords = model.keywords;
    targeting.localExtras = model.localExtras;
    targeting.userDataKeywords = model.userDataKeywords;
    [adManager loadRewardedVideoAdWithUserId:model.userId targeting:targeting];
}

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid {
    MobiRewardedVideo *sharedInstance = [[self class] sharedInstance];
    MobiRewardedVideoAdManager *adManager = sharedInstance.rewardedVideoAdManagers[posid];

    return [adManager hasAdAvailable];
}

/// 返回posid对应的有效奖励数组
/// @param posid 广告位id
+ (NSArray *)availableRewardsForPosid:(NSString *)posid {
    MobiRewardedVideo *sharedInstance = [[self class] sharedInstance];
    MobiRewardedVideoAdManager *adManager = sharedInstance.rewardedVideoAdManagers[posid];

    return adManager.availableRewards;
}

/// 返回看完激励视频后给用户的奖励,默认情况下,返回的是`availableRewardsForPosid`的第一个元素
/// @param posid 广告位id
+ (MobiRewardedVideoReward *)selectedRewardForPosid:(NSString *)posid {
    MobiRewardedVideo *sharedInstance = [[self class] sharedInstance];
    MobiRewardedVideoAdManager *adManager = sharedInstance.rewardedVideoAdManagers[posid];

    return adManager.selectedReward;
}

/// 播放一个激励视频广告
/// @param posid 激励视频广告的posid
/// @param viewController 用来present出视频广告的控制器
/// @param reward 看完广告给的奖励,从`availableRewardsForPosid`中选出的一种奖励,可为nil
/// 注意:在调用此方法之前,需要先调用`hasAdAvailableForPosid`方法判断视频广告是否有效,
+ (void)showRewardedVideoAdForPosid:(NSString *)posid fromViewController:(UIViewController *)viewController withReward:(MobiRewardedVideoReward *)reward {
    MobiRewardedVideo *sharedInstance = [[self class] sharedInstance];
    MobiRewardedVideoAdManager *adManager = sharedInstance.rewardedVideoAdManagers[posid];

    if (!adManager) {
//        MPLogInfo(@"The rewarded video could not be shown: "
//                  @"no ads have been loaded for adUnitID: %@", adUnitID);

        return;
    }

    if (!viewController) {
//        MPLogInfo(@"The rewarded video could not be shown: "
//                  @"a nil view controller was passed to -presentRewardedVideoAdForAdUnitID:fromViewController:.");

        return;
    }

    if (![viewController.view.window isKeyWindow]) {
//        MPLogInfo(@"Attempting to present a rewarded video ad in non-key window. The ad may not render properly.");
    }

    [adManager presentRewardedVideoAdFromViewController:viewController withReward:reward];
}

// MARK: - MobiRewardedVideoAdManagerDelegate
- (void)rewardedVideoDidLoadForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidLoad:)]) {
        [delegate rewardedVideoAdDidLoad:self];
    }
}

- (void)rewardedVideoAdVideoDidLoadForAdManager:(MobiRewardedVideoAdManager *)manager {
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdVideoDidLoad:)]) {
        [delegate rewardedVideoAdVideoDidLoad:self];
    }
}

- (void)rewardedVideoDidFailToLoadForAdManager:(MobiRewardedVideoAdManager *)manager error:(NSError *)error
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidFailToLoad:error:)]) {
        [delegate rewardedVideoAdDidFailToLoad:self error:error];
    }
}

- (void)rewardedVideoDidExpireForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidExpire:)]) {
        [delegate rewardedVideoAdDidExpire:self];
    }
}

- (void)rewardedVideoDidFailToPlayForAdManager:(MobiRewardedVideoAdManager *)manager error:(NSError *)error
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidFailToPlay:error:)]) {
        [delegate rewardedVideoAdDidFailToPlay:self error:error];
    }
}

- (void)rewardedVideoWillAppearForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdWillAppear:)]) {
        [delegate rewardedVideoAdWillAppear:self];
    }
}

- (void)rewardedVideoDidAppearForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidAppear:)]) {
        [delegate rewardedVideoAdDidAppear:self];
    }
}

- (void)rewardedVideoWillDisappearForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdWillDisappear:)]) {
        [delegate rewardedVideoAdWillDisappear:self];
    }
}

- (void)rewardedVideoDidDisappearForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidDisappear:)]) {
        [delegate rewardedVideoAdDidDisappear:self];
    }

    // 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
//    Class customEventClass = manager.customEventClass;

//    for (id key in self.rewardedVideoAdManagers) {
//        MobiRewardedVideoAdManager *adManager = self.rewardedVideoAdManagers[key];
//
//        if (adManager != manager && adManager.customEventClass == customEventClass) {
//            [adManager handleAdPlayedForCustomEventNetwork];
//        }
//    }
}

- (void)rewardedVideoDidReceiveTapEventForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdDidReceiveTapEvent:)]) {
        [delegate rewardedVideoAdDidReceiveTapEvent:self];
    }
}

/// 暂时不需要提示给用户
- (void)rewardedVideoAdManager:(MobiRewardedVideoAdManager *)manager didReceiveImpressionEventWithImpressionData:(MPImpressionData *)impressionData
{
//    [MoPub sendImpressionNotificationFromAd:nil
//                                   adUnitID:manager.adUnitId
//                             impressionData:impressionData];

//    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
//    if ([delegate respondsToSelector:@selector(didTrackImpressionWithAdUnitID:impressionData:)]) {
//        [delegate didTrackImpressionWithAdUnitID:manager.posid impressionData:impressionData];
//    }
}

- (void)rewardedVideoWillLeaveApplicationForAdManager:(MobiRewardedVideoAdManager *)manager
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdWillLeaveApplication:)]) {
        [delegate rewardedVideoAdWillLeaveApplication:self];
    }
}

- (void)rewardedVideoShouldRewardUserForAdManager:(MobiRewardedVideoAdManager *)manager reward:(MobiRewardedVideoReward *)reward
{
    id<MobiRewardedVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(rewardedVideoAdShouldReward:reward:)]) {
        [delegate rewardedVideoAdShouldReward:self reward:reward];
    }
}

// MARK: - Private

+ (MobiRewardedVideo *)sharedInstance
{
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        gSharedInstance = [[self alloc] init];
    });

    return gSharedInstance;
}

@end
