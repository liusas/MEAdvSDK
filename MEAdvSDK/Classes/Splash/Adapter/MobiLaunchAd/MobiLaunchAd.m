//
//  MobiLaunchAd.m
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "MobiLaunchAd.h"
#import "MobiLaunchImageView.h"
#import "MobiLaunchAdImageView.h"
#import "MobiLaunchAdButton.h"
#import "MobiLaunchAdCache.h"
#import "MobiLaunchAdWebViewController.h"
#import "UIViewController+MobiNav.h"
#import "MobiAdNativeBaseClass.h"
#import "MobiSplashError.h"

typedef NS_ENUM(NSInteger, MobiLaunchAdType) {
    MobiLaunchAdTypeImage,
    MobiLaunchAdTypeVideo
};

static MobiSourceType _sourceType = MobiSourceTypeLaunchScreen;
static MobiLaunchAd * instance = nil;
static dispatch_once_t oneToken;

@interface MobiLaunchAd ()

@property(nonatomic,assign) MobiLaunchAdType launchAdType;
@property(nonatomic,assign) NSInteger waitDataDuration;
@property(nonatomic,strong) MobiLaunchImageAdConfiguration * imageAdConfiguration;
@property(nonatomic,strong) MobiLaunchAdButton * skipButton;
@property (nonatomic, strong) id<MPAdDestinationDisplayAgent> destinationDisplayAgent;
//@property(nonatomic,strong)XHLaunchVideoAdConfiguration * videoAdConfiguration;
//@property(nonatomic,strong)XHLaunchAdVideoView * adVideoView;
@property(nonatomic,strong) UIView * windowView;
@property(nonatomic,copy) dispatch_source_t skipTimer;

@end

@implementation MobiLaunchAd

//MARK: 暴露在外面的方法

//设置launch的来源
+ (void)setLaunchSourceType:(MobiSourceType)sourceType{
    _sourceType = sourceType;
}

//设置开屏图片
+ (MobiLaunchAd *)imageAdWithImageAdConfiguration:(MobiLaunchImageAdConfiguration *)imageAdconfiguration{
    return [MobiLaunchAd imageAdWithImageAdConfiguration:imageAdconfiguration delegate:nil];
}

//设置开屏图片及代理
+ (MobiLaunchAd *)imageAdWithImageAdConfiguration:(MobiLaunchImageAdConfiguration *)imageAdconfiguration delegate:(id)delegate{
    MobiLaunchAd *launchAd = [MobiLaunchAd shareLaunchAd];
    if(delegate) launchAd.delegate = delegate;
    launchAd.imageAdConfiguration = imageAdconfiguration;
    return launchAd;
}

// 批量下载并缓存
+ (void)downLoadImageAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray{
    [self downLoadImageAndCacheWithURLArray:urlArray completed:nil];
}

+ (void)downLoadImageAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray completed:(nullable MobiLaunchAdBatchDownLoadAndCacheCompletedBlock)completedBlock{
    if(urlArray.count==0) return;
    [[MobiLaunchAdDownloader sharedDownloader] downLoadImageAndCacheWithURLArray:urlArray completed:completedBlock];
}

// Action
+ (void)removeAndAnimated:(BOOL)animated{
    [[MobiLaunchAd shareLaunchAd] removeAndAnimated:animated];
}

// 是否已缓存
+ (BOOL)checkImageInCacheWithURL:(NSURL *)url{
    return [MobiLaunchAdCache checkImageInCacheWithURL:url];
}

// 获取缓存url
+ (NSString *)cacheImageURLString{
    return [MobiLaunchAdCache getCacheImageUrl];
}

// 缓存/清理相关
+ (void)clearDiskCache{
    [MobiLaunchAdCache clearDiskCache];
}

+ (void)clearDiskCacheWithImageUrlArray:(NSArray<NSURL *> *)imageUrlArray{
    [MobiLaunchAdCache clearDiskCacheWithImageUrlArray:imageUrlArray];
}

+ (void)clearDiskCacheExceptImageUrlArray:(NSArray<NSURL *> *)exceptImageUrlArray{
    [MobiLaunchAdCache clearDiskCacheExceptImageUrlArray:exceptImageUrlArray];
}

+ (float)diskCacheSize{
    return [MobiLaunchAdCache diskCacheSize];
}

+ (NSString *)mobiLaunchAdCachePath{
    return [MobiLaunchAdCache mobiLaunchAdCachePath];
}

// MARK: - <MPAdDestinationDisplayAgentDelegate>

- (UIViewController *)viewControllerForPresentingModalView
{
    return _imageAdConfiguration.window.rootViewController;
}

- (void)displayAgentWillPresentModal
{
    [self removeAndAnimateDefault];
    [self.delegate splashAdWillPresentFullScreenModalForLaunchAd:self];
}

- (void)displayAgentWillLeaveApplication
{
    [self removeAndAnimateDefault];
    [self.delegate splashAdDidDismissFullScreenModalForLaunchAd:self];
}

- (void)displayAgentDidDismissModal
{
    [self.delegate splashAdWillDismissFullScreenModalForLaunchAd:self];
    [self.delegate splashAdDidDismissFullScreenModalForLaunchAd:self];
}

//MARK: private
+ (MobiLaunchAd *)shareLaunchAd {
    dispatch_once(&oneToken,^{
        instance = [[MobiLaunchAd alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        MobiWeakSelf
        [self setupLaunchAd];
        
        self.destinationDisplayAgent = [MPAdDestinationDisplayAgent agentWithDelegate:self];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            ///应用进入后台时回调
            if ([weakSelf.delegate respondsToSelector:@selector(splashAdApplicationWillEnterBackgroundForLaunchAd:)]) {
                [weakSelf.delegate splashAdApplicationWillEnterBackgroundForLaunchAd:weakSelf];
            }
            [weakSelf removeOnly];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:MobiLaunchAdDetailPageWillShowNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            
            ///开屏广告点击以后即将弹出开屏广告详情页
            if ([weakSelf.delegate respondsToSelector:@selector(splashAdWillPresentFullScreenModalForLaunchAd:)]) {
                [weakSelf.delegate splashAdWillPresentFullScreenModalForLaunchAd:weakSelf];
            }
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:MobiLaunchAdDetailPageDidShowNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            
            ///开屏广告点击以后已经弹出开屏广告详情页
            if ([weakSelf.delegate respondsToSelector:@selector(splashAdDidPresentFullScreenModalForLaunchAd:)]) {
                [weakSelf.delegate splashAdDidPresentFullScreenModalForLaunchAd:weakSelf];
            }
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:MobiLaunchAdDetailPageWillDismissNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            
            ///开屏广告详情页即将关闭
            if ([weakSelf.delegate respondsToSelector:@selector(splashAdWillDismissFullScreenModalForLaunchAd:)]) {
                [weakSelf.delegate splashAdWillDismissFullScreenModalForLaunchAd:weakSelf];
            }
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:MobiLaunchAdDetailPageDismissNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            ///开屏广告详情页已经关闭
            if ([weakSelf.delegate respondsToSelector:@selector(splashAdDidDismissFullScreenModalForLaunchAd:)]) {
                [weakSelf.delegate splashAdDidDismissFullScreenModalForLaunchAd:weakSelf];
            }
        }];
    }
    return self;
}

- (void)setupLaunchAd{
    
    UIView *windowView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    windowView.backgroundColor = [UIColor blueColor];
    windowView.hidden = NO;
    windowView.alpha = 1;
    _windowView = windowView;
    
//    /** 添加launchImageView */
//    [_windowView addSubview:[[MobiLaunchImageView alloc] initWithSourceType:_sourceType]];
    
}

/**根据configuration配置展示图片*/
- (void)setupImageAdForConfiguration:(MobiLaunchImageAdConfiguration *)configuration {
    if(_windowView == nil) return;
    [self removeSubViewsExceptLaunchAdImageView];
    MobiLaunchAdImageView *adImageView = [[MobiLaunchAdImageView alloc] init];
    [_windowView addSubview:adImageView];
    /** frame */
    if(configuration.frame.size.width > 0 && configuration.frame.size.height > 0) adImageView.frame = configuration.frame;
    if(configuration.contentMode) adImageView.contentMode = configuration.contentMode;
    //下载图片
    if(configuration.imageNameOrURLString.length && MobiISURLString(configuration.imageNameOrURLString)){//imageNameOrURLString不为空且url
        [MobiLaunchAdCache async_saveImageUrl:configuration.imageNameOrURLString];
        if(!configuration.imageOption) configuration.imageOption = MobiLaunchAdImageDefault;
        MobiWeakSelf
        [adImageView mobi_setImageWithURL:[NSURL URLWithString:configuration.imageNameOrURLString] placeholderImage:nil GIFImageCycleOnce:configuration.GIFImageCycleOnce options:configuration.imageOption GIFImageCycleOnceFinish:^{
            //GIF不循环,播放完成
            [[NSNotificationCenter defaultCenter] postNotificationName:MobiLaunchAdGIFImageCycleOnceFinishNotification object:nil userInfo:@{@"imageNameOrURLString":configuration.imageNameOrURLString}];
            
        } completed:^(UIImage *image,NSData *imageData,NSError *error,NSURL *url){
            
            if(error){
                if ([weakSelf.delegate respondsToSelector:@selector(splashAdFailToPresentForLaunchAd:withError:)]) {
                    NSError *error = [NSError splashErrorWithCode:MobiSplashAdErrorNoAdsAvailable localizedDescription:@"无效的开屏广告"];
                    [weakSelf.delegate splashAdFailToPresentForLaunchAd:self withError:error];
                }
                [self removeAndAnimateDefault];
            }
        }];
        if(configuration.imageOption == MobiLaunchAdImageCacheInBackground){
            /** 缓存中未有 */
            if(![MobiLaunchAdCache checkImageInCacheWithURL:[NSURL URLWithString:configuration.imageNameOrURLString]]){
                [self removeAndAnimateDefault]; return; /** 完成显示 */
            }
        }
    }else{
        if(configuration.imageNameOrURLString.length){//imageNameOrURLString不为空则查找本地
            NSData *data = MobiDataWithFileName(configuration.imageNameOrURLString);
            if(MobiISGIFTypeWithData(data)){
                FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
                adImageView.animatedImage = image;
                adImageView.image = nil;
                __weak typeof(adImageView) w_adImageView = adImageView;
                adImageView.loopCompletionBlock = ^(NSUInteger loopCountRemaining) {
                    if(configuration.GIFImageCycleOnce){
                        [w_adImageView stopAnimating];
                        MobiLaunchAdLog(@"GIF不循环,播放完成");
                        [[NSNotificationCenter defaultCenter] postNotificationName:MobiLaunchAdGIFImageCycleOnceFinishNotification object:@{@"imageNameOrURLString":configuration.imageNameOrURLString}];
                    }
                };
            }else{
                adImageView.animatedImage = nil;
                adImageView.image = [UIImage imageWithData:data];
            }
        }else{
            MobiLaunchAdLog(@"未设置广告图片");
        }
    }
    /** skipButton */
    [self addSkipButtonForConfiguration:configuration];
    [self startSkipDispathTimer];
    /** customView */
    if(configuration.subViews.count > 0)  [self addSubViews:configuration.subViews];
    
    ///将加载好的开屏广告添加到window
    [self.imageAdConfiguration.window addSubview:_windowView];
    
    /** 开屏广告成功展示 */
    if ([self.delegate respondsToSelector:@selector(splashAdSuccessPresentScreenForLaunchAd:)]) {
        [self.delegate splashAdSuccessPresentScreenForLaunchAd:self];
    }
    /** 开屏广告曝光回调 */
    if ([self.delegate respondsToSelector:@selector(splashAdExposuredForLaunchAd:)]) {
        [self.delegate splashAdExposuredForLaunchAd:self];
    }
    
    MobiWeakSelf
    adImageView.click = ^(CGPoint downPoint, CGPoint upPoint) {
        [weakSelf clickAndPoint:downPoint upPoint:upPoint];
    };
}

- (void)addSkipButtonForConfiguration:(MobiLaunchAdConfiguration *)configuration{
    if(!configuration.duration) configuration.duration = 5;
    if(!configuration.skipButtonType) configuration.skipButtonType = MobiSkipTypeTimeText;
    if(configuration.customSkipView){
        [_windowView addSubview:configuration.customSkipView];
    }else{
        if(_skipButton == nil){
            _skipButton = [[MobiLaunchAdButton alloc] initWithSkipType:configuration.skipButtonType];
            _skipButton.hidden = YES;
            [_skipButton addTarget:self action:@selector(skipButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        }
        [_windowView addSubview:_skipButton];
        [_skipButton setTitleWithSkipType:configuration.skipButtonType duration:configuration.duration];
    }
}

- (void)startSkipDispathTimer{
    MobiLaunchAdConfiguration * configuration = [self commonConfiguration];
    if(!configuration.skipButtonType) configuration.skipButtonType = MobiSkipTypeTimeText;//默认
    __block NSInteger duration = 5;//默认
    if(configuration.duration) duration = configuration.duration;
    if(configuration.skipButtonType == MobiSkipTypeRoundProgressTime || configuration.skipButtonType == MobiSkipTypeRoundProgressText){
        [_skipButton startRoundDispathTimerWithDuration:duration];
    }
    NSTimeInterval period = 1.0;
    _skipTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(_skipTimer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_skipTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            ///开屏广告剩余时间回调
            if ([self.delegate respondsToSelector:@selector(splashAdCustomSkipView:LifeTime:)]) {
                [self.delegate splashAdCustomSkipView:configuration.customSkipView LifeTime:duration];
            }
            if(!configuration.customSkipView){
                [self->_skipButton setTitleWithSkipType:configuration.skipButtonType duration:duration];
            }
            if(duration==0){
                DISPATCH_SOURCE_CANCEL_SAFE(self->_skipTimer);
                [self removeAndAnimate]; return ;
            }
            duration--;
        });
    });
    dispatch_resume(_skipTimer);
}

//MARK: addsubViews

-(void)addSubViews:(NSArray *)subViews{
    [subViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [_windowView addSubview:view];
    }];
}

//MARK: set
- (void)setImageAdConfiguration:(MobiLaunchImageAdConfiguration *)imageAdConfiguration{
    _imageAdConfiguration = imageAdConfiguration;
    _launchAdType = MobiLaunchAdTypeImage;
    [self setupImageAdForConfiguration:imageAdConfiguration];
}

//MARK: commonConfiguration

- (MobiLaunchAdConfiguration *)commonConfiguration{
    MobiLaunchAdConfiguration *configuration = nil;
    switch (_launchAdType) {
//        case MobiLaunchAdTypeVideo:
//            configuration = _videoAdConfiguration;
//            break;
        case MobiLaunchAdTypeImage:
            configuration = _imageAdConfiguration;
            break;
        default:
            break;
    }
    return configuration;
}

//MARK: Action

///跳过按钮点击
-(void)skipButtonClick:(MobiLaunchAdButton *)button{
    ///开屏广告将要关闭回调
    if ([self.delegate respondsToSelector:@selector(splashAdWillClosedForLaunchAd:)]) {
        [self.delegate splashAdWillClosedForLaunchAd:self];
    }
    [self removeAndAnimated:YES];
}

-(void)removeAndAnimated:(BOOL)animated{
    if(animated){
        [self removeAndAnimate];
    }else{
        [self remove];
    }
}

///点击页面跳转到广告详情页面
-(void)clickAndPoint:(CGPoint)downPoint upPoint:(CGPoint)upPoint {
    MobiLaunchAdConfiguration * configuration = [self commonConfiguration];
    
    MobiLaunchAdReportModel *model = [MobiLaunchAdReportModel new];
    model.clickDownPoint = downPoint;
    model.clickUpPoint = upPoint;
    
    /// 开屏广告点击回调
    if ([self.delegate respondsToSelector:@selector(splashAdClickedForLaunchAd:reportModel:)]) {
        [self.delegate splashAdClickedForLaunchAd:self reportModel:model];
    }
    
    if (configuration.openModel) {//如果openModel有值
        
        MobiAdNativeBaseClass *native = (MobiAdNativeBaseClass *)configuration.openModel;
        
        NSMutableDictionary *resolveDic = [NSMutableDictionary dictionary];
        resolveDic[@"ctype"] = @(native.ctype);
        resolveDic[@"curl"] = native.curl;
        resolveDic[@"durl"] = native.dlinkDurl;
        resolveDic[@"wurl"] = native.dlinkWurl;
        resolveDic[@"dlink_track"] = native.dlinkTrack;
        
        [self.destinationDisplayAgent displayDestinationForDict:resolveDic downPoint:downPoint upPoint:upPoint];
        
    }
}

//MARK: remove方法

///移除开屏页，根据不同的MobiShowFinishAnimate类型，显示不同的消失动画
-(void)removeAndAnimate{
    
    MobiLaunchAdConfiguration * configuration = [self commonConfiguration];
    CGFloat duration = showFinishAnimateTimeDefault;
    if(configuration.showFinishAnimateTime>0) duration = configuration.showFinishAnimateTime;
    switch (configuration.showFinishAnimate) {
        case MobiShowFinishAnimateNone:{
            [self remove];
        }
            break;
        case MobiShowFinishAnimateFadein:{
            [self removeAndAnimateDefault];
        }
            break;
        case MobiShowFinishAnimateLite:{
            [UIView transitionWithView:_windowView duration:duration options:UIViewAnimationOptionCurveEaseOut animations:^{
                self->_windowView.transform = CGAffineTransformMakeScale(1.5, 1.5);
                self->_windowView.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        case MobiShowFinishAnimateFlipFromLeft:{
            [UIView transitionWithView:_windowView duration:duration options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                self->_windowView.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        case MobiShowFinishAnimateFlipFromBottom:{
            [UIView transitionWithView:_windowView duration:duration options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
                self->_windowView.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        case MobiShowFinishAnimateCurlUp:{
            [UIView transitionWithView:_windowView duration:duration options:UIViewAnimationOptionTransitionCurlUp animations:^{
                self->_windowView.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        default:{
            [self removeAndAnimateDefault];
        }
            break;
    }
}

///移除开屏，动画类型为MobiShowFinishAnimateFadein
-(void)removeAndAnimateDefault{
    [self removeWindowLaunchImageView];
    MobiLaunchAdConfiguration * configuration = [self commonConfiguration];
    CGFloat duration = showFinishAnimateTimeDefault;
    if(configuration.showFinishAnimateTime>0) duration = configuration.showFinishAnimateTime;
    [UIView transitionWithView:_windowView duration:duration options:UIViewAnimationOptionTransitionNone animations:^{
        self->_windowView.alpha = 0;
    } completion:^(BOOL finished) {
        [self remove];
    }];
}

///将开屏移除，触发代理
-(void)remove{
    [self removeWindowLaunchImageView];
    [self removeOnly];
    
    ///开屏广告关闭回调
    if ([self.delegate respondsToSelector:@selector(splashAdClosedForLaunchAd:)]) {
        [self.delegate splashAdClosedForLaunchAd:self];
    }
    
}

///移除操作真正的实现，所有移除操作都在此处进行
-(void)removeOnly{
    DISPATCH_SOURCE_CANCEL_SAFE(_skipTimer)
    REMOVE_FROM_SUPERVIEW_SAFE(_skipButton)
//    if(_launchAdType == XHLaunchAdTypeVideo){
//        if(_adVideoView){
//            [_adVideoView stopVideoPlayer];
//            REMOVE_FROM_SUPERVIEW_SAFE(_adVideoView)
//        }
//    }
    
    if(_windowView){
        [_windowView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            REMOVE_FROM_SUPERVIEW_SAFE(obj)
        }];
        _windowView.hidden = YES;
        _windowView = nil;
        
        //移除单例，否则一直存在
        instance = nil;
        oneToken = 0;
    }
}

///在每次setupImageAdForConfiguration时，移除除了MobiLaunchImageView的子视图
-(void)removeSubViewsExceptLaunchAdImageView{
    [_windowView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(![obj isKindOfClass:[MobiLaunchImageView class]]){
            REMOVE_FROM_SUPERVIEW_SAFE(obj)
        }
    }];
}

///移除在window上获取的启动图MobiLaunchImageView
- (void)removeWindowLaunchImageView {
    
    [_imageAdConfiguration.window.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[MobiLaunchImageView class]]) {
            REMOVE_FROM_SUPERVIEW_SAFE(obj);
            *stop = YES;
        }
    }];
}

///移除通知
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.destinationDisplayAgent cancel];
    [self.destinationDisplayAgent setDelegate:nil];
}


@end

@implementation MobiLaunchAdReportModel
@end
