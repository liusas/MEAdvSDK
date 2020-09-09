//
//  MEBannerView.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/9/9.
//

#import "MEBannerView.h"

@interface MEBannerView ()

@property (nonatomic, assign) BOOL hasMovedToWindow;
@property (nonatomic, strong) UIView *bannerView;
@property (strong, nonatomic) NSArray<NSLayoutConstraint *> *webViewLayoutConstraints;

@end

@implementation MEBannerView

- (instancetype)initWithBannerView:(UIView *)bannerView frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _bannerView = bannerView;
        [self setUp];
    }
    return self;
}

- (void)setUp {
    [self retainBannerViewOffscreen:self.bannerView];
}

// WKWebView won't load/execute javascript unless it's on the view hierarchy. Because the MoPub SDK uses a lot of
// javascript before adding the view to the hierarchy, let's stick the WKWebView into an offscreen-but-on-the-window
// view, and move it to self when self gets a window.
static UIView *gOffscreenView = nil;

- (void)retainBannerViewOffscreen:(UIView *)banner {
    if (!gOffscreenView) {
        gOffscreenView = [self constructOffscreenView];
    }
    [gOffscreenView addSubview:banner];
}

- (void)cleanUpOffscreenView {
    if (gOffscreenView.subviews.count == 0) {
        [gOffscreenView removeFromSuperview];
        gOffscreenView = nil;
    }
}

- (UIView *)constructOffscreenView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.clipsToBounds = YES;

    UIWindow *appWindow = [[UIApplication sharedApplication] keyWindow];
    [appWindow addSubview:view];

    return view;
}

// 在视图发生变化时,回调此方法
- (void)didMoveToWindow {
    // If using WKWebView, and if MPWebView is in the view hierarchy, and if the WKWebView is in the offscreen view currently,
    // move our WKWebView to self and deallocate OffscreenView if no other MPWebView is using it.
    if (self.bannerView
        && !self.hasMovedToWindow
        && self.window != nil
        && [self.bannerView.superview isEqual:gOffscreenView]) {
        self.bannerView.frame = self.bounds;
        [self addSubview:self.bannerView];
        [self constrainView:self.bannerView shouldUseSafeArea:NO];
        self.hasMovedToWindow = YES;

        // Don't keep OffscreenView if we don't need it; it can always be re-allocated again later
        [self cleanUpOffscreenView];
    }
}

- (void)constrainView:(UIView *)view shouldUseSafeArea:(BOOL)shouldUseSafeArea {
    if (@available(iOS 11, *)) {
        view.translatesAutoresizingMaskIntoConstraints = NO;

        if (self.webViewLayoutConstraints) {
            [NSLayoutConstraint deactivateConstraints:self.webViewLayoutConstraints];
        }

        if (shouldUseSafeArea) {
            self.webViewLayoutConstraints = @[
                [view.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor],
                [view.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor],
                [view.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor],
                [view.bottomAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.bottomAnchor],
            ];
        } else {
            self.webViewLayoutConstraints = @[
                [view.topAnchor constraintEqualToAnchor:self.topAnchor],
                [view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                [view.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            ];
        }

        [NSLayoutConstraint activateConstraints:self.webViewLayoutConstraints];
    }
}

- (void)dealloc {
    // Be sure our WKWebView doesn't stay stuck to the static OffscreenView
    [self.bannerView removeFromSuperview];
}

@end
