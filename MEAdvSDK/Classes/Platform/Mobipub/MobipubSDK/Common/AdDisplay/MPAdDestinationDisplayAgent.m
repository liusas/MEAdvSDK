//
//  MPAdDestinationDisplayAgent.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPAdDestinationDisplayAgent.h"
#import "MPLastResortDelegate.h"
#import "NSURL+MPAdditions.h"
#import "MPCoreInstanceProvider.h"
#import "MobiAnalyticsTracker.h"
#import "MobiExperimentProvider.h"
#import "MobiPub+Utility.h"
#import "SKStoreProductViewController+MPAdditions.h"
#import <SafariServices/SafariServices.h>
#import "MPURLResolver.h"

static NSString * const kDisplayAgentErrorDomain = @"com.mopub.displayagent";

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPAdDestinationDisplayAgent () <SFSafariViewControllerDelegate, SKStoreProductViewControllerDelegate>

//@property (nonatomic, strong) MPURLResolver *resolver;
//@property (nonatomic, strong) MPURLResolver *enhancedDeeplinkFallbackResolver;

@property (nonatomic, strong) MobiAdClickResolver *resolver;
@property (nonatomic, strong) MobiAdClickResolver *enhancedDeeplinkFallbackResolver;

@property (nonatomic, strong) MPProgressOverlayView *overlayView;
@property (nonatomic, assign) BOOL isLoadingDestination;
@property (nonatomic) MobiPubDisplayAgentType displayAgentType;
@property (nonatomic, strong) SKStoreProductViewController *storeKitController;
@property (nonatomic, strong) SFSafariViewController *safariController;

@property (nonatomic, strong) MPActivityViewControllerHelper *activityViewControllerHelper;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPAdDestinationDisplayAgent

@synthesize delegate;

+ (MPAdDestinationDisplayAgent *)agentWithDelegate:(id<MPAdDestinationDisplayAgentDelegate>)delegate
{
    MPAdDestinationDisplayAgent *agent = [[MPAdDestinationDisplayAgent alloc] init];
    agent.delegate = delegate;
    agent.overlayView = [[MPProgressOverlayView alloc] initWithDelegate:agent];
    agent.activityViewControllerHelper = [[MPActivityViewControllerHelper alloc] initWithDelegate:agent];
    agent.displayAgentType = MobiExperimentProvider.sharedInstance.displayAgentType;
    return agent;
}

- (void)dealloc
{
    [self dismissAllModalContent];

    self.overlayView.delegate = nil;

    // XXX: If this display agent is deallocated while a StoreKit controller is still on-screen,
    // nil-ing out the controller's delegate would leave us with no way to dismiss the controller
    // in the future. Therefore, we change the controller's delegate to a singleton object which
    // implements SKStoreProductViewControllerDelegate and is always around.
    self.storeKitController.delegate = [MPLastResortDelegate sharedDelegate];
}

- (void)dismissAllModalContent
{
    [self.overlayView hide];
}

+ (BOOL)shouldDisplayContentInApp
{
    switch (MobiExperimentProvider.sharedInstance.displayAgentType) {
        case MobiPubDisplayAgentTypeInApp:
            return YES;
        case MobiPubDisplayAgentTypeNativeSafari:
            return NO;
    }
}

/// 根据URL判断如何展示点击广告后的效果页
- (void)displayDestinationForURL:(NSURL *)URL
{
    if (self.isLoadingDestination) return;
    self.isLoadingDestination = YES;

    [self.delegate displayAgentWillPresentModal];
    [self.overlayView show];

    [self.resolver cancel];
    [self.enhancedDeeplinkFallbackResolver cancel];

    __weak __typeof__(self) weakSelf = self;
    self.resolver = [MPURLResolver resolverWithURL:URL completion:^(MPURLActionInfo *suggestedAction, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error) {
            [strongSelf failedToResolveURLWithError:error];
        } else {
            [strongSelf handleSuggestedURLAction:suggestedAction isResolvingEnhancedDeeplink:NO];
        }
    }];

    [self.resolver start];
}

- (void)displayDestinationForDict:(NSDictionary *)resolveDic downPoint:(CGPoint)downPoint upPoint:(CGPoint)upPoint {
    if (self.isLoadingDestination) return;
    self.isLoadingDestination = YES;
    
    [self.delegate displayAgentWillPresentModal];
    [self.overlayView show];
    
    [self.resolver cancel];
    [self.enhancedDeeplinkFallbackResolver cancel];
    
    // 替换落地页宏
    resolveDic = [NSDictionary dictionaryWithDictionary:[self replaceTheCurlWithDict:resolveDic downPoint:downPoint upPoint:upPoint]];
    
    __weak __typeof__(self) weakSelf = self;
    self.resolver = [MobiAdClickResolver resolverWithDict:resolveDic completion:^(MPURLActionInfo *actionInfo, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error) {
            [strongSelf failedToResolveURLWithError:error];
        } else {
            [strongSelf handleSuggestedURLAction:actionInfo isResolvingEnhancedDeeplink:NO];
        }
    }];
    
    [self.resolver start];
}

/// 替换 curl 中的宏,在 click 后,跳转落地页前,要替换掉宏以后才能跳转
- (NSDictionary *)replaceTheCurlWithDict:(NSDictionary *)resolveDic downPoint:(CGPoint)downPoint upPoint:(CGPoint)upPoint {
    NSMutableDictionary *mutDic = [NSMutableDictionary dictionaryWithDictionary:resolveDic];
    mutDic[@"curl"] = [[MobiAnalyticsTracker sharedTracker] replaceMacroFromUrlString:resolveDic[@"curl"] withClickDownPoint:downPoint clickUpPoint:upPoint];
    return mutDic;
}

- (void)cancel
{
    if (self.isLoadingDestination) {
        [self.resolver cancel];
        [self.enhancedDeeplinkFallbackResolver cancel];
        [self hideOverlay];
        [self completeDestinationLoading];
    }
}

- (BOOL)handleSuggestedURLAction:(MPURLActionInfo *)actionInfo isResolvingEnhancedDeeplink:(BOOL)isResolvingEnhancedDeeplink
{
    if (actionInfo == nil) {
        [self failedToResolveURLWithError:[NSError errorWithDomain:kDisplayAgentErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL action"}]];
        return NO;
    }

    BOOL success = YES;

    switch (actionInfo.actionType) {
        case MPURLActionTypeStoreKit:
            [self showStoreKitWithAction:actionInfo];
            break;
        case MPURLActionTypeGenericDeeplink:
            [self openURLInApplication:actionInfo.deeplinkURL];
            break;
        case MPURLActionTypeEnhancedDeeplink:
            if (isResolvingEnhancedDeeplink) {
                // We end up here if we encounter a nested enhanced deeplink. We'll simply disallow
                // this to avoid getting into cycles.
                [self failedToResolveURLWithError:[NSError errorWithDomain:kDisplayAgentErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Cannot resolve an enhanced deeplink that is nested within another enhanced deeplink."}]];
                success = NO;
            } else {
                [self handleEnhancedDeeplinkRequest:actionInfo.enhancedDeeplinkRequest];
            }
            break;
        case MPURLActionTypeOpenInSafari:
            [self openURLInApplication:actionInfo.safariDestinationURL];
            break;
        case MPURLActionTypeOpenInWebView:
            [self showWebViewWithHTMLString:actionInfo.HTTPResponseString baseURL:actionInfo.webViewBaseURL actionType:MPURLActionTypeOpenInWebView];
            break;
        case MPURLActionTypeOpenURLInWebView:
            [self showWebViewWithHTMLString:actionInfo.HTTPResponseString baseURL:actionInfo.originalURL actionType:MPURLActionTypeOpenInWebView];
            break;
        case MPURLActionTypeShare:
            [self openShareURL:actionInfo.shareURL];
            break;
        default:
            [self failedToResolveURLWithError:[NSError errorWithDomain:kDisplayAgentErrorDomain code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Unrecognized URL action type."}]];
            success = NO;
            break;
    }

    return success;
}

- (void)handleEnhancedDeeplinkRequest:(MPEnhancedDeeplinkRequest *)request
{
    [MobiPub openURL:request.primaryURL options:@{} completion:^(BOOL didOpenURLSuccessfully) {
        if (didOpenURLSuccessfully) {
            [self hideOverlay];
            [self.delegate displayAgentWillLeaveApplication];
            [self completeDestinationLoading];
            
            NSArray *urls = [NSArray arrayWithArray:[[MobiAnalyticsTracker sharedTracker] replaceMacroFromURLStrings:request.primaryTrackingURLs withClickDownPoint:CGPointZero clickUpPoint:CGPointZero]];
            [[MobiAnalyticsTracker sharedTracker] sendTrackingRequestForURLs:urls];
        } else if (request.fallbackURL) {
            [self handleEnhancedDeeplinkFallbackForRequest:request];
        } else {
            [self openURLInApplication:request.originalURL];
        }
    }];
}

//- (void)handleEnhancedDeeplinkFallbackForRequest:(MPEnhancedDeeplinkRequest *)request
//{
//    __weak __typeof__(self) weakSelf = self;
//    [self.enhancedDeeplinkFallbackResolver cancel];
//    self.enhancedDeeplinkFallbackResolver = [MPURLResolver resolverWithURL:request.fallbackURL completion:^(MPURLActionInfo *actionInfo, NSError *error) {
//        __typeof__(self) strongSelf = weakSelf;
//        if (error) {
//            // If the resolver fails, just treat the entire original URL as a regular deeplink.
//            [strongSelf openURLInApplication:request.originalURL];
//        }
//        else {
//            // Otherwise, the resolver will return us a URL action. We process that action
//            // normally with one exception: we don't follow any nested enhanced deeplinks.
//            BOOL success = [strongSelf handleSuggestedURLAction:actionInfo isResolvingEnhancedDeeplink:YES];
//            if (success) {
//                [[MobiAnalyticsTracker sharedTracker] sendTrackingRequestForURLStrs:request.fallbackTrackingURLs];
//            }
//        }
//    }];
//    [self.enhancedDeeplinkFallbackResolver start];
//}

- (void)handleEnhancedDeeplinkFallbackForRequest:(MPEnhancedDeeplinkRequest *)request {
    __weak __typeof__(self) weakSelf = self;
    [self.enhancedDeeplinkFallbackResolver cancel];
    
// 海外
    self.enhancedDeeplinkFallbackResolver = [MPURLResolver resolverWithURL:request.fallbackURL completion:^(MPURLActionInfo *actionInfo, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error) {
            // If the resolver fails, just treat the entire original URL as a regular deeplink.
            [strongSelf openURLInApplication:request.originalURL];
        }
        else {
            // Otherwise, the resolver will return us a URL action. We process that action
            // normally with one exception: we don't follow any nested enhanced deeplinks.
            BOOL success = [strongSelf handleSuggestedURLAction:actionInfo isResolvingEnhancedDeeplink:YES];
            if (success) {
                [[MobiAnalyticsTracker sharedTracker] sendTrackingRequestForURLStrs:request.fallbackTrackingURLs];
            }
        }
    }];
    
//    国内
//    NSMutableDictionary *resolveNewDic = [NSMutableDictionary dictionary];
//    resolveNewDic[@"curl"] = request.fallbackURL.absoluteString;
//    resolveNewDic[@"durl"] = request.primaryURL.absoluteString;
//    resolveNewDic[@"dlink_track"] = request.fallbackTrackingURLs;
//    resolveNewDic[@"ctype"] = @(1);// 若deeplink没打开app,则去下载
    
//    self.enhancedDeeplinkFallbackResolver = [MobiAdClickResolver resolverWithDict:resolveNewDic completion:^(MPURLActionInfo *actionInfo, NSError *error) {
//        __typeof__(self) strongSelf = weakSelf;
//        if (error) {
//            // If the resolver fails, just treat the entire original URL as a regular deeplink.
//            [strongSelf openURLInApplication:request.originalURL];
//        }
//        else {
//            // Otherwise, the resolver will return us a URL action. We process that action
//            // normally with one exception: we don't follow any nested enhanced deeplinks.
//            BOOL success = [strongSelf handleSuggestedURLAction:actionInfo isResolvingEnhancedDeeplink:YES];
//            if (success) {
//                [[MobiAnalyticsTracker sharedTracker] sendTrackingRequestForURLStrs:request.fallbackTrackingURLs];
//            }
//        }
//    }];
    
    [self.enhancedDeeplinkFallbackResolver start];
}

- (void)showWebViewWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)URL actionType:(MPURLActionType)actionType {
    switch (self.displayAgentType) {
        case MobiPubDisplayAgentTypeInApp:
            self.safariController = ({
                SFSafariViewController * controller = [[SFSafariViewController alloc] initWithURL:URL];
                controller.delegate = self;
                controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                controller.modalPresentationStyle = UIModalPresentationFullScreen;
                controller;
            });

            [self showAdBrowserController];
            break;
        case MobiPubDisplayAgentTypeNativeSafari:
            [self openURLInApplication:URL];
            break;
    }
}

- (void)showAdBrowserController {
    [self hideOverlay];
    [[self.delegate viewControllerForPresentingModalView] presentViewController:self.safariController
                                                                       animated:Mobi_ANIMATED
                                                                     completion:nil];
}

- (void)showStoreKitProductWithParameters:(NSDictionary *)parameters fallbackURL:(NSURL *)URL
{
    if (!SKStoreProductViewController.canUseStoreProductViewController) {
        [self openURLInApplication:URL];
        return;
    }

    [self presentStoreKitControllerWithProductParameters:parameters fallbackURL:URL];
}

- (void)openURLInApplication:(NSURL *)URL
{
    [self hideOverlay];

    [MobiPub openURL:URL options:@{} completion:^(BOOL didOpenURLSuccessfully) {
        if (didOpenURLSuccessfully) {
            [self.delegate displayAgentWillLeaveApplication];
        }
        [self completeDestinationLoading];
    }];
}

- (BOOL)openShareURL:(NSURL *)URL
{
//    MPLogDebug(@"MPAdDestinationDisplayAgent - loading Share URL: %@", URL);
    MPMoPubShareHostCommand command = [URL mp_MoPubShareHostCommand];
    switch (command) {
        case MPMoPubShareHostCommandTweet:
            return [self.activityViewControllerHelper presentActivityViewControllerWithTweetShareURL:URL];
        default:
//            MPLogInfo(@"MPAdDestinationDisplayAgent - unsupported Share URL: %@", [URL absoluteString]);
            return NO;
    }
}

- (void)failedToResolveURLWithError:(NSError *)error
{
    [self hideOverlay];
    [self completeDestinationLoading];
}

- (void)completeDestinationLoading
{
    self.isLoadingDestination = NO;
    [self.delegate displayAgentDidDismissModal];
}

- (void)presentStoreKitControllerWithProductParameters:(NSDictionary *)parameters fallbackURL:(NSURL *)URL
{
    self.storeKitController = [[SKStoreProductViewController alloc] init];
    self.storeKitController.modalPresentationStyle = UIModalPresentationFullScreen;
    self.storeKitController = [[SKStoreProductViewController alloc] init];
    self.storeKitController.delegate = self;
    [self.storeKitController loadProductWithParameters:parameters completionBlock:nil];

    [self hideOverlay];
    [[self.delegate viewControllerForPresentingModalView] presentViewController:self.storeKitController animated:Mobi_ANIMATED completion:nil];
}

#pragma mark - <SKStoreProductViewControllerDelegate>

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    self.isLoadingDestination = NO;
    [viewController dismissViewControllerAnimated:YES completion:nil];
    [self hideModalAndNotifyDelegate];
}

#pragma mark - <SFSafariViewControllerDelegate>

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    self.isLoadingDestination = NO;
    [self.delegate displayAgentDidDismissModal];
}

#pragma mark - <MPProgressOverlayViewDelegate>

- (void)overlayCancelButtonPressed
{
    [self cancel];
}

#pragma mark - Convenience Methods

- (void)hideModalAndNotifyDelegate
{
#warning 点击广告后,暂不处理上层控制器
//    [[self.delegate viewControllerForPresentingModalView] dismissViewControllerAnimated:Mobi_ANIMATED completion:^{
//        [self.delegate displayAgentDidDismissModal];
//    }];
}

- (void)hideOverlay
{
    [self.overlayView hide];
}

#pragma mark <MPActivityViewControllerHelperDelegate>

- (UIViewController *)viewControllerForPresentingActivityViewController
{
    return self.delegate.viewControllerForPresentingModalView;
}

- (void)activityViewControllerWillPresent
{
    [self hideOverlay];
    self.isLoadingDestination = NO;
    [self.delegate displayAgentWillPresentModal];
}

- (void)activityViewControllerDidDismiss
{
    [self.delegate displayAgentDidDismissModal];
}

#pragma mark - Experiment with 3 display agent types: 0 -> keep existing, 1 -> use native safari, 2 -> use SafariViewController

- (void)showStoreKitWithAction:(MPURLActionInfo *)actionInfo
{
    switch (self.displayAgentType) {
        case MobiPubDisplayAgentTypeInApp:
            [self showStoreKitProductWithParameters:actionInfo.iTunesStoreParameters
                                        fallbackURL:actionInfo.iTunesStoreFallbackURL];
            break;
        case MobiPubDisplayAgentTypeNativeSafari:
            [self openURLInApplication:actionInfo.iTunesStoreFallbackURL];
            break;
        default:
            break;
    }
}

@end
