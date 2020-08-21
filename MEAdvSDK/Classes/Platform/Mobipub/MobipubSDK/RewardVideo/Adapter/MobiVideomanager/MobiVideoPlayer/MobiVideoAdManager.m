//
//  MobiVideoAdManager.m
//  MobiPubSDK
//
//  Created by 李新丰 on 2020/8/7.
//

#import "MobiVideoAdManager.h"


static MobiVideoAdManager *manager = nil;
static NSInteger defaultWaitDataDuration = 3;
@interface MobiVideoAdManager ()<MobiXFVideoPlayControllerDelegate,MPAdDestinationDisplayAgentDelegate>

@property (nonatomic, strong) NSURL *contenURL;
@property(nonatomic,assign) NSInteger waitDataDuration;
@property(nonatomic,strong) MobiVideoAdConfiguration * videoAdConfiguration;

@end

@implementation MobiVideoAdManager

+ (MobiVideoAdManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MobiVideoAdManager alloc] init];
    });
    return manager;
}

+(void)setWaitDataDuration:(NSInteger )waitDataDuration{
    MobiVideoAdManager *launchAd = [MobiVideoAdManager shareManager];
    launchAd.waitDataDuration = waitDataDuration;
}

+(MobiVideoAdManager *)videoAdWithVideoAdConfiguration:(MobiVideoAdConfiguration *)videoAdconfiguration{
    return [MobiVideoAdManager videoAdWithVideoAdConfiguration:videoAdconfiguration delegate:nil];
}

+(MobiVideoAdManager *)videoAdWithVideoAdConfiguration:(MobiVideoAdConfiguration *)videoAdconfiguration delegate:(nullable id)delegate{
    MobiVideoAdManager *launchAd = [MobiVideoAdManager shareManager];
    if(delegate) launchAd.delegate = delegate;
    launchAd.videoAdConfiguration = videoAdconfiguration;
    return launchAd;
}

+(void)downLoadVideoAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray{
    [self downLoadVideoAndCacheWithURLArray:urlArray completed:nil];
}

+(void)downLoadVideoAndCacheWithURLArray:(NSArray <NSURL *> * )urlArray completed:(nullable MobiVideoAdBatchDownLoadAndCacheCompletedBlock)completedBlock{
    if(urlArray.count==0) return;
    [[MobiVideoAdDownloader sharedDownloader] downLoadVideoAndCacheWithURLArray:urlArray completed:completedBlock];
}

+(BOOL)checkImageInCacheWithURL:(NSURL *)url{
    return [MobiVideoAdCache checkImageInCacheWithURL:url];
}

+(BOOL)checkVideoInCacheWithURL:(NSURL *)url{
    return [MobiVideoAdCache checkVideoInCacheWithURL:url];
}
+(void)clearDiskCache{
    [MobiVideoAdCache clearDiskCache];
}

+(void)clearDiskCacheWithVideoUrlArray:(NSArray<NSURL *> *)videoUrlArray{
    [MobiVideoAdCache clearDiskCacheWithVideoUrlArray:videoUrlArray];
}

+(void)clearDiskCacheExceptVideoUrlArray:(NSArray<NSURL *> *)exceptVideoUrlArray{
    [MobiVideoAdCache clearDiskCacheExceptVideoUrlArray:exceptVideoUrlArray];
}

+(float)diskCacheSize{
    return [MobiVideoAdCache diskCacheSize];
}

+(NSString *)xhLaunchAdCachePath{
    return [MobiVideoAdCache xhLaunchAdCachePath];
}

+(NSString *)cacheVideoURLString{
    return [MobiVideoAdCache getCacheVideoUrl];
}


#pragma mark - private
//+(MobiVideoAdManager *)shareLaunchAd{
//    static MobiVideoAdManager *instance = nil;
//    static dispatch_once_t oneToken;
//    dispatch_once(&oneToken,^{
//        instance = [[MobiVideoAdManager alloc] init];
//    });
//    return instance;
//}

- (instancetype)init{
    self = [super init];
    if (self) {
        //[self setupLaunchAd];
        self.destinationDisplayAgent = [MPAdDestinationDisplayAgent agentWithDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            //[self setupLaunchAdEnterForeground];
        }];
    }
    return self;
}


/**视频*/
-(void)setupVideoAdForConfiguration:(MobiVideoAdConfiguration *)configuration{
    /** video 数据源 */
    if(configuration.videoNameOrURLString.length && MobiISURLString(configuration.videoNameOrURLString)){
        //[MobiVideoAdCache async_saveVideoUrl:configuration.videoNameOrURLString];
        NSURL *pathURL = [MobiVideoAdCache getCacheVideoWithURL:[NSURL URLWithString:configuration.videoNameOrURLString]];
//        NSURL *pathURL = [NSURL URLWithString:configuration.videoNameOrURLString];
        if(pathURL){
            self.contenURL = pathURL;
            [self presentTopPlayVideoWithController:self.controller];
//            _adVideoView.contentURL = pathURL;
//            _adVideoView.muted = configuration.muted;
//            [_adVideoView.videoPlayer.player play];
        }else{
            [[MobiVideoAdDownloader sharedDownloader] downloadVideoWithURL:[NSURL URLWithString:configuration.videoNameOrURLString] progress:^(unsigned long long total, unsigned long long current) {
            }  completed:^(NSURL * _Nullable location, NSError * _Nullable error){
                if(!error){
                    if ([self.delegate respondsToSelector:@selector(rewardedVideoShowSuccess:)]) {
                        [self.delegate rewardedVideoShowSuccess:self];
                    }
                } else {
                    if ([self.delegate respondsToSelector:@selector(rewardedVideoShowFailed:)]) {
                        [self.delegate rewardedVideoShowFailed:self];
                    }
                }
            }];
            /***视频缓存,提前显示完成 */
            //[self removeAndAnimateDefault]; return;
        }
    }else{
        if(configuration.videoNameOrURLString.length){
            NSURL *pathURL = nil;
            NSURL *cachePathURL = [[NSURL alloc] initFileURLWithPath:[MobiVideoAdCache videoPathWithFileName:configuration.videoNameOrURLString]];
            //若本地视频未在沙盒缓存文件夹中
            if (![MobiVideoAdCache checkVideoInCacheWithFileName:configuration.videoNameOrURLString]) {
                /***如果不在沙盒文件夹中则将其复制一份到沙盒缓存文件夹中/下次直接取缓存文件夹文件,加快文件查找速度 */
                NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:configuration.videoNameOrURLString withExtension:nil];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[NSFileManager defaultManager] copyItemAtURL:bundleURL toURL:cachePathURL error:nil];
                });
                pathURL = bundleURL;
            }else{
                pathURL = cachePathURL;
            }
            
            if(pathURL){
                if ([self.delegate respondsToSelector:@selector(rewardedVideo:didLoadAdSuccess:)]) {
                    [self.delegate rewardedVideo:self didLoadAdSuccess:pathURL];
                }
                self.contenURL = pathURL;
                [self presentTopPlayVideoWithController:self.controller];
//                _adVideoView.contentURL = pathURL;
//                _adVideoView.muted = configuration.muted;
//                [_adVideoView.videoPlayer.player play];
                
            }else{
                MobiLaunchAdLog(@"Error:广告视频未找到,请检查名称是否有误!");
            }
        }else{
            MobiLaunchAdLog(@"未设置广告视频");
        }
    }
    /** skipButton */
//    [self addSkipButtonForConfiguration:configuration];
//    [self startSkipDispathTimer];
    
}

- (void)presentTopPlayVideoWithController:(UIViewController *)controller{
    MobiXFVideoPlayController *vc = [[MobiXFVideoPlayController alloc] init];
    vc.contenURL = manager.contenURL;
    vc.videoDataBase = manager.videoDataBase;
    vc.delegate = self;
    vc.playType = 0;
    [manager.controller presentViewController:vc animated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(rewardedVideoShowSuccess)]) {
            [self.delegate rewardedVideoShowSuccess:self];
        }
    }];
}


#pragma mark - set
-(void)setVideoAdConfiguration:(MobiVideoAdConfiguration *)videoAdConfiguration{
    _videoAdConfiguration = videoAdConfiguration;
    [self setupVideoAdForConfiguration:videoAdConfiguration];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self setupVideoAdForConfiguration:videoAdConfiguration];
//    });
}

-(void)setWaitDataDuration:(NSInteger)waitDataDuration{
    _waitDataDuration = waitDataDuration;
    /** 数据等待 */
    //[self startWaitDataDispathTiemr];
}


-(MobiVideoAdConfiguration *)commonConfiguration{
    MobiVideoAdConfiguration *configuration = nil;
    configuration = _videoAdConfiguration;
    return configuration;
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
     [self.destinationDisplayAgent cancel];
     [self.destinationDisplayAgent setDelegate:nil];
}


#pragma mark -- MobiXFVideoPlayControllerDelegate ---
- (void)rewardedVideoCloseClick{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoCloseClick:)]) {
        [self.delegate rewardedVideoCloseClick:self];
    }
}

- (void)rewardedVideoDownloadClick{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoDownloadClick:)]) {
        [self.delegate rewardedVideoDownloadClick:self];
    }
    if (manager.videoDataBase) {//如果openModel有值
        
        NSMutableDictionary *resolveDic = [NSMutableDictionary dictionary];
        resolveDic[@"ctype"] = @(manager.videoDataBase.ctype);
        resolveDic[@"curl"] = manager.videoDataBase.curl;
        resolveDic[@"durl"] = manager.videoDataBase.dlink_durl;
        resolveDic[@"wurl"] = manager.videoDataBase.dlink_wurl;
        resolveDic[@"dlink_track"] = manager.videoDataBase.dlink_track;
        
        [self.destinationDisplayAgent displayDestinationForDict:resolveDic downPoint:CGPointZero upPoint:CGPointZero];
    }
}

- (void)mobiVideoPlayProgress:(MobiVideoPlayProgressType)progressType{
    if (self.delegate && [self.delegate respondsToSelector:@selector(mobiVideoAd:videoPlayProgress:)]) {
        [self.delegate mobiVideoAd:self videoPlayProgress:progressType];
    }
}

// MARK: - <MPAdDestinationDisplayAgentDelegate>

- (UIViewController *)viewControllerForPresentingModalView
{
    //return [UIApplication sharedApplication].delegate.window.rootViewController;
    return manager.controller.presentedViewController;
}

- (void)displayAgentWillPresentModal
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoWillLeaveApp:)]) {
        [self.delegate rewardedVideoWillLeaveApp:self];
    }
}

- (void)displayAgentWillLeaveApplication
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardedVideoWillLeaveApp:)]) {
        [self.delegate rewardedVideoWillLeaveApp:self];
    }
}

- (void)displayAgentDidDismissModal
{
    
}

@end

