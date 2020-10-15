//
//  MobiFullscreen.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import "MobiFullscreen.h"
#import "MobiFullscreenAdManager.h"
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"
#import "MobiFullscreenError.h"
#import "MobiFullscreenModel.h"

static MobiFullscreen *gSharedInstance = nil;

@interface MobiFullscreen ()<MobiFullscreenAdManagerDelegate>

@property (nonatomic, strong) NSMutableDictionary *fullscreenVideoAdManagers;
/// 存放不同posid对应的delegate
@property (nonatomic, strong) NSMapTable<NSString *, id<MobiFullscreenVideoDelegate>> * delegateTable;

+ (MobiFullscreen *)sharedInstance;

@end

@implementation MobiFullscreen

- (instancetype)init {
    if (self = [super init]) {
        _fullscreenVideoAdManagers = [[NSMutableDictionary alloc] init];

        // Keys (ad unit ID) are strong, values (delegates) are weak.
        _delegateTable = [NSMapTable strongToWeakObjectsMapTable];
    }

    return self;
}

/// 设置用来接收posid对应的激励视频回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiFullscreenVideoDelegate>)delegate forPosid:(NSString *)posid {
    if (posid == nil) {
        return;
    }
    
    [[[self class] sharedInstance].delegateTable setObject:delegate forKey:posid];
}

/// 从有效的posid中删除对应的接收激励视频回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiFullscreenVideoDelegate>)delegate {
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
+ (void)loadFullscreenVideoAdWithPosid:(NSString *)posid fullscreenVideoModel:(MobiFullscreenModel *)model {
    MobiFullscreen *sharedInstance = [[self class] sharedInstance];
    
    if (![posid length]) {
        NSError *error = [NSError errorWithDomain:MobiFullscreenVideoAdsSDKDomain code:MobiFullscreenVideoAdErrorInvalidPosid userInfo:nil];
        id<MobiFullscreenVideoDelegate> delegate = [sharedInstance.delegateTable objectForKey:posid];
        [delegate fullscreenVideoAdDidFailToLoad:sharedInstance error:error];
        return;
    }
    
    if (model != nil) {
        sharedInstance.fullscreenModel = model;
    }
    sharedInstance.posid = posid;
    
    MobiFullscreenAdManager *adManager = sharedInstance.fullscreenVideoAdManagers[posid];

    if (!adManager) {
        adManager = [[MobiFullscreenAdManager alloc] initWithPosid:posid delegate:sharedInstance];
        sharedInstance.fullscreenVideoAdManagers[posid] = adManager;
    }

    // 广告目标锁定,都是便于更精准的投放广告
    MobiAdTargeting *targeting = [MobiAdTargeting targetingWithCreativeSafeSize:MPApplicationFrame(YES).size];
    targeting.keywords = model.keywords;
    targeting.localExtras = model.localExtras;
    targeting.userDataKeywords = model.userDataKeywords;
    [adManager loadFullscreenVideoAdWithUserId:model.userId targeting:targeting];
}

/// 判断posid对应的视频广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid {
    MobiFullscreen *sharedInstance = [[self class] sharedInstance];
    MobiFullscreenAdManager *adManager = sharedInstance.fullscreenVideoAdManagers[posid];

    return [adManager hasAdAvailable];
}

+ (void)showFullscreenVideoAdForPosid:(NSString *)posid fromViewController:(UIViewController *)viewController {
    MobiFullscreen *sharedInstance = [[self class] sharedInstance];
    MobiFullscreenAdManager *adManager = sharedInstance.fullscreenVideoAdManagers[posid];

    if (!adManager) {
//        MPLogInfo(@"The rewarded video could not be shown: "
//                  @"no ads have been loaded for adUnitID: %@", adUnitID);

        return;
    }

    if (!viewController) {
//        MPLogInfo(@"The rewarded video could not be shown: "
//                  @"a nil view controller was passed to -presentfullscreenVideoAdForAdUnitID:fromViewController:.");

        return;
    }

    if (![viewController.view.window isKeyWindow]) {
//        MPLogInfo(@"Attempting to present a rewarded video ad in non-key window. The ad may not render properly.");
    }

    [adManager presentFullscreenVideoAdFromViewController:viewController];
}

// MARK: - MobiFullscreenAdManagerDelegate
- (void)fullscreenVideoDidLoadForAdManager:(MobiFullscreenAdManager *)manager {
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidLoad:)]) {
        [delegate fullscreenVideoAdDidLoad:self];
    }
}

- (void)fullscreenVideoAdVideoDidLoadForAdManager:(MobiFullscreenAdManager *)manager {
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdVideoDidLoad:)]) {
        [delegate fullscreenVideoAdVideoDidLoad:self];
    }
}

- (void)fullscreenVideoDidFailToLoadForAdManager:(MobiFullscreenAdManager *)manager error:(NSError *)error {
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidFailToLoad:error:)]) {
        [delegate fullscreenVideoAdDidFailToLoad:self error:error];
    }
}

- (void)fullscreenVideoDidExpireForAdManager:(MobiFullscreenAdManager *)manager {
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidExpire:)]) {
        [delegate fullscreenVideoAdDidExpire:self];
    }
}

- (void)fullscreenVideoAdViewRenderFailForAdManager:(MobiFullscreenAdManager *)manager error:(NSError *)error {
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdViewRenderFail:error:)]) {
        [delegate fullscreenVideoAdViewRenderFail:self error:error];
    }
}

- (void)fullscreenVideoWillAppearForAdManager:(MobiFullscreenAdManager *)manager
{
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdWillAppear:)]) {
        [delegate fullscreenVideoAdWillAppear:self];
    }
}

- (void)fullscreenVideoDidAppearForAdManager:(MobiFullscreenAdManager *)manager
{
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidAppear:)]) {
        [delegate fullscreenVideoAdDidAppear:self];
    }
}

- (void)fullscreenVideoAdDidPlayFinishForAdManager:(MobiFullscreenAdManager *)manager didFailWithError:(NSError *)error {
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidPlayFinish:didFailWithError:)]) {
        [delegate fullscreenVideoAdDidPlayFinish:self didFailWithError:error];
    }
}

- (void)fullscreenVideoWillDisappearForAdManager:(MobiFullscreenAdManager *)manager
{
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdWillDisappear:)]) {
        [delegate fullscreenVideoAdWillDisappear:self];
    }
}

- (void)fullscreenVideoDidDisappearForAdManager:(MobiFullscreenAdManager *)manager
{
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidDisappear:)]) {
        [delegate fullscreenVideoAdDidDisappear:self];
    }

    // 有时可能会同时 load 多个广告,在某些情况下,两个 load 拉取的是相同的广告,这个回调表示播放完毕,因此其他 load 的广告需要判断是否失效,如果失效,需要调用 expire 代理,提示上层,广告已经过期,需要重新拉取
    Class customEventClass = manager.customEventClass;

    for (id key in self.fullscreenVideoAdManagers) {
        MobiFullscreenAdManager *adManager = self.fullscreenVideoAdManagers[key];

        if (adManager != manager && adManager.customEventClass == customEventClass) {
            [adManager handleAdPlayedForCustomEventNetwork];
        }
    }
}

- (void)fullscreenVideoDidReceiveTapEventForAdManager:(MobiFullscreenAdManager *)manager
{
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidReceiveTapEvent:)]) {
        [delegate fullscreenVideoAdDidReceiveTapEvent:self];
    }
}

/// 暂时不需要提示给用户
//- (void)fullscreenVideoAdManager:(MobiFullscreenAdManager *)manager didReceiveImpressionEventWithImpressionData:(MPImpressionData *)impressionData
//{
//    [MoPub sendImpressionNotificationFromAd:nil
//                                   adUnitID:manager.adUnitId
//                             impressionData:impressionData];

//    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
//    if ([delegate respondsToSelector:@selector(didTrackImpressionWithAdUnitID:impressionData:)]) {
//        [delegate didTrackImpressionWithAdUnitID:manager.posid impressionData:impressionData];
//    }
//}

- (void)fullscreenVideoWillLeaveApplicationForAdManager:(MobiFullscreenAdManager *)manager
{
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdWillLeaveApplication:)]) {
        [delegate fullscreenVideoAdWillLeaveApplication:self];
    }
}

- (void)fullscreenVideoAdDidClickSkip:(MobiFullscreenAdManager *)manager {
    id<MobiFullscreenVideoDelegate> delegate = [self.delegateTable objectForKey:manager.posid];
    if ([delegate respondsToSelector:@selector(fullscreenVideoAdDidClickSkip:)]) {
        [delegate fullscreenVideoAdDidClickSkip:self];
    }
}

// MARK: - Private

+ (MobiFullscreen *)sharedInstance
{
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        gSharedInstance = [[self alloc] init];
    });

    return gSharedInstance;
}

@end
