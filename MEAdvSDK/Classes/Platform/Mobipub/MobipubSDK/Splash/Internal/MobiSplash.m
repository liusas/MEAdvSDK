//
//  MobiSplash.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import "MobiSplash.h"
#import "MobiSplashAdManager.h"
#import "MobiAdTargeting.h"
#import "MobiGlobal.h"
#import "MobiSplashError.h"
#import "MobiSplashModel.h"
#import "MobiLaunchImageView.h"

static MobiSplash *gSharedInstance = nil;

@interface MobiSplash ()<MobiSplashAdManagerDelegate>

@property (nonatomic, strong) NSMutableDictionary *splashAdManagers;
/// 存放不同posid对应的delegate
@property (nonatomic, strong) NSMapTable<NSString *, id<MobiSplashDelegate>> * delegateTable;

@property (nonatomic, strong) UIWindow *window;

+ (MobiSplash *)sharedInstance;

@end

@implementation MobiSplash

- (instancetype)init {
    if (self = [super init]) {
        _splashAdManagers = [[NSMutableDictionary alloc] init];
    
        // Keys (ad unit ID) are strong, values (delegates) are weak.
        _delegateTable = [NSMapTable strongToWeakObjectsMapTable];
    }

    return self;
}

/// 设置用来接收posid对应的广告回调事件的delegate
/// @param delegate 代理
/// @param posid 广告位id
+ (void)setDelegate:(id<MobiSplashDelegate>)delegate forPosid:(NSString *)posid {
    if (posid == nil) {
        return;
    }
    
    [[[self class] sharedInstance].delegateTable setObject:delegate forKey:posid];
}

/// 从有效的posid中删除对应的接收广告回调事件的delegate
/// @param delegate 代理
+ (void)removeDelegate:(id<MobiSplashDelegate>)delegate {
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

/// 加载开屏广告
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid, fetchDelay, backgroundImage等),可为nil
+ (void)loadSplashAdAndShowWithWindow:(UIWindow *)window posid:(NSString *)posid SplashModel:(MobiSplashModel *)model {
    [self loadSplashAdAndShowWithWindow:window posid:posid SplashModel:model withBottomView:nil];
}

/// 加载开屏广告
/// 发起拉取广告请求,并将获取的广告以半屏形式展示在传入的Window的上半部，剩余部分展示传入的bottomView       请注意1.bottomView需设置好宽高，所占的空间不能过大，并保证高度不超过屏幕高度的 25%。2.Splash广告只支持竖屏
/// @param posid 广告位id
/// @param model 拉取广告信息所需的其他配置信息(如userid, fetchDelay, backgroundImage等),可为nil
/// @param bottomView 自定义底部View，可以在此View中设置应用Logo
+ (void)loadSplashAdAndShowWithWindow:(UIWindow *)window posid:(NSString *)posid SplashModel:(MobiSplashModel *)model withBottomView:(UIView *)bottomView {
    MobiSplash *sharedInstance = [[self class] sharedInstance];
    
    if (![posid length]) {
        NSError *error = [NSError errorWithDomain:MobiSplashAdsSDKDomain code:MobiSplashAdErrorInvalidPosid userInfo:nil];
        id<MobiSplashDelegate> delegate = [sharedInstance.delegateTable objectForKey:posid];
        [delegate splashAdFailToPresent:sharedInstance withError:error];
        return;
    }
    
    if (!window) {
        return;
    }
    
    if (model != nil) {
        sharedInstance.splashModel = model;
    }
    
    sharedInstance.posid = posid;
    
    sharedInstance.window = window;
    
    MobiSplashAdManager *adManager = sharedInstance.splashAdManagers[posid];

    if (!adManager) {
        adManager = [[MobiSplashAdManager alloc] initWithPosid:posid delegate:sharedInstance];
        sharedInstance.splashAdManagers[posid] = adManager;
    }

    // 广告目标锁定,都是便于更精准的投放广告
    MobiAdTargeting *targeting = [MobiAdTargeting targetingWithCreativeSafeSize:MPApplicationFrame(YES).size];
    targeting.keywords = model.keywords;
    targeting.localExtras = model.localExtras;
    targeting.userDataKeywords = model.userDataKeywords;
    [adManager loadSplashAdWithUserId:model.userId targeting:targeting];
    
    /** 添加launchImageView */
    [window addSubview:[[MobiLaunchImageView alloc] initWithSourceType:MobiSourceTypeLaunchImage]];
    
}

+ (void)stopSplashAdWithPosid:(NSString *)posid {
    MobiSplash *sharedInstance = [[self class] sharedInstance];
    MobiSplashAdManager *adManager = sharedInstance.splashAdManagers[posid];
    [adManager stopSplashAdWithPosid:posid];
}

/// 判断posid对应的开屏广告是否有效
/// @param posid 广告位id
+ (BOOL)hasAdAvailableForPosid:(NSString *)posid {
    MobiSplash *sharedInstance = [[self class] sharedInstance];
    MobiSplashAdManager *adManager = sharedInstance.splashAdManagers[posid];

    return [adManager hasAdAvailable];
}

/// 预加载闪屏广告接口
/// @param posid 广告位ID
+ (void)preloadSplashOrderWithPosid:(NSString *)posid {
    
}

//MARK: private



// MARK: - MobiSplashAdManagerDelegate
/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoadForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdDidLoadForManager:)]) {
        [delegate splashAdDidLoad:self];
    }
    [splashAd presentSplashAdFromWindow:self.window];
}

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresentForManager:(MobiSplashAdManager *)splashAd withError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *view in self.window.subviews) {
            if ([view isKindOfClass:[MobiLaunchImageView class]]) {
                [view removeFromSuperview];
            }
        }
    });
    
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdFailToPresent:withError:)]) {
        [delegate splashAdFailToPresent:self withError:error];
    }
}


/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreenForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdSuccessPresentScreen:)]) {
        [delegate splashAdSuccessPresentScreen:self];
    }
}
/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackgroundForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdApplicationWillEnterBackground:)]) {
        [delegate splashAdApplicationWillEnterBackground:self];
    }
}

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposuredForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdExposured:)]) {
        [delegate splashAdExposured:self];
    }
}

/**
 *  开屏广告点击回调
 */
- (void)splashAdClickedForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdClicked:)]) {
        [delegate splashAdClicked:self];
    }
}

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosedForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdWillClosed:)]) {
        [delegate splashAdWillClosed:self];
    }
}

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosedForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdClosed:)]) {
        [delegate splashAdClosed:self];
    }
}

/**
 * 当一个posid加载完的开屏广告资源失效时(过期),回调此方法
 */
- (void)splashAdDidExpireForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdDidExpire:)]) {
        [delegate splashAdDidExpire:self];
    }
}

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModalForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdWillPresentFullScreenModal:)]) {
        [delegate splashAdWillPresentFullScreenModal:self];
    }
}

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModalForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdDidPresentFullScreenModal:)]) {
        [delegate splashAdDidPresentFullScreenModal:self];
    }
}

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModalForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdWillDismissFullScreenModal:)]) {
        [delegate splashAdWillDismissFullScreenModal:self];
    }
}

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModalForManager:(MobiSplashAdManager *)splashAd {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenModal:)]) {
        [delegate splashAdDidDismissFullScreenModal:self];
    }
}

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdForManager:(MobiSplashAdManager *)splashAd lifeTime:(NSUInteger)time {
    id<MobiSplashDelegate> delegate = [self.delegateTable objectForKey:splashAd.posid];
    if ([delegate respondsToSelector:@selector(splashAd:lifeTime:)]) {
        [delegate splashAd:self lifeTime:time];
    }
}


// MARK: - Private

+ (MobiSplash *)sharedInstance {
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        gSharedInstance = [[self alloc] init];
    });

    return gSharedInstance;
}

@end
