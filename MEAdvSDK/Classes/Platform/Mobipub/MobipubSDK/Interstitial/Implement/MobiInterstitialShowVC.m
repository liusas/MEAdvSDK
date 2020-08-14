//
//  MobiInterstitialShowVC.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/8/11.
//

#import "MobiInterstitialShowVC.h"
#import "MobiLaunchAdCache.h"
#import "MPAdDestinationDisplayAgent.h"// 展示点击广告后的效果的代理类

@interface MobiInterstitialShowVC ()

@property (nonatomic, strong) UIImageView *imageContainer;
@property (nonatomic, strong) id<MPAdDestinationDisplayAgent> destinationDisplayAgent;

// 手指按下的点
@property (nonatomic, assign) CGPoint downPoint;
// 手指抬起的点
@property (nonatomic, assign) CGPoint upPoint;

@end

@implementation MobiInterstitialShowVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.destinationDisplayAgent = [MPAdDestinationDisplayAgent agentWithDelegate:self];
    
    
    [self setUp];
}

- (void)setUp {
    if (!self.imageContainer) {
        self.imageContainer = [[UIImageView alloc] init];
        [self.view addSubview:self.imageContainer];
        
        UIImage *image = [MobiLaunchAdCache getCacheImageWithURL:[NSURL URLWithString:self.imgUrl]];
        if (image) {
            self.imageContainer.image = image;
            [self containerSizeLayoutWithSize:image.size];
        }
    }
}

// MARK: - Public
- (void)dismissInterstitialAnimated:(BOOL)animated {
    [super dismissInterstitialAnimated:animated];
}

- (BOOL)shouldDisplayCloseButton {
    return YES;
}

- (void)willPresentInterstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialWillAppear:)]) {
        [self.delegate interstitialWillAppear:self];
    }
}

- (void)didPresentInterstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialDidAppear:)]) {
        [self.delegate interstitialDidAppear:self];
    }
}

- (void)willDismissInterstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialWillDisappear:)]) {
        [self.delegate interstitialWillDisappear:self];
    }
}

- (void)didDismissInterstitial {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialDidDisappear:)]) {
        [self.delegate interstitialDidDisappear:self];
    }
}

- (void)layoutCloseButton {
    [super layoutCloseButton];
    
    CGFloat originX = self.view.bounds.size.width - 5.0 -
    self.closeButton.bounds.size.width;
    self.closeButton.frame = CGRectMake(originX,
                                        self.imageContainer.frame.origin.y + 5.0,
                                        self.closeButton.bounds.size.width,
                                        self.closeButton.bounds.size.height);
}

// MARK: - Event
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = self.downPoint = [touch locationInView:self.view];
    if (CGRectContainsPoint(self.imageContainer.frame, point)) {
    } else {
        [self dismissInterstitialAnimated:Mobi_ANIMATED];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.upPoint = [touch locationInView:self.view];
    
    if (CGRectContainsPoint(self.imageContainer.frame, self.upPoint)) {
        // 点击了图片容器
        [self receiveTapEventWithDownPoint:self.downPoint upPoint:self.upPoint];
    }
}

- (void)receiveTapEventWithDownPoint:(CGPoint)downPoint upPoint:(CGPoint)upPoint {
    MobiAdNativeBaseClass *native = self.configuration.nativeConfigData;
    NSMutableDictionary *resolveDic = [NSMutableDictionary dictionary];
    resolveDic[@"ctype"] = @(native.ctype);
    resolveDic[@"curl"] = native.curl;
    resolveDic[@"durl"] = native.dlinkDurl;
    resolveDic[@"wurl"] = native.dlinkWurl;
    resolveDic[@"dlink_track"] = native.dlinkTrack;
    
    [self.destinationDisplayAgent displayDestinationForDict:resolveDic downPoint:downPoint upPoint:upPoint];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialDidReceiveTapEvent:)]) {
        [self.delegate interstitialDidReceiveTapEvent:self];
    }
}

// MARK: - <MPAdDestinationDisplayAgentDelegate>

- (UIViewController *)viewControllerForPresentingModalView
{
    return self;
}

- (void)displayAgentWillPresentModal
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialWillPresentModal:)]) {
        [self.delegate interstitialWillPresentModal:self];
    }
}

- (void)displayAgentWillLeaveApplication
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialWillLeaveApplication:)]) {
        [self.delegate interstitialWillLeaveApplication:self];
    }
}

- (void)displayAgentDidDismissModal
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialDidDismissModal:)]) {
        [self.delegate interstitialDidDismissModal:self];
    }
}

// MARK: - Private
// 广告容器的大小
- (void)containerSizeLayoutWithSize:(CGSize)size {
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        [self sizeFitLayout:size];
        return;
    }
    
    [self sizeFitLayout:CGSizeMake(self.width, self.height)];
}

- (void)sizeFitLayout:(CGSize)targetSize {
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    if (targetSize.width > CGRectGetWidth(self.view.frame) || targetSize.height > CGRectGetHeight(self.view.frame)) {
        targetWidth = CGRectGetWidth(self.view.frame);
        targetHeight = targetWidth * (targetSize.height/targetSize.width)*1.0;
    }
    
    self.imageContainer.frame = CGRectMake(0, 0, targetWidth, targetHeight);
    self.imageContainer.center = self.view.center;
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.destinationDisplayAgent cancel];
    [self.destinationDisplayAgent setDelegate:nil];
}

@end
