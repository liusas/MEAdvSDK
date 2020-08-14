//
//  MobiLaunchAdWebViewController.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/28.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "MobiLaunchAdWebViewController.h"
#import <WebKit/WebKit.h>
#import "MobiLaunchAd.h"

@interface MobiLaunchAdWebViewController ()
@property(nonatomic,strong)WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@end

@implementation MobiLaunchAdWebViewController

-(void)dealloc
{
    /**
     在广告详情控制器销毁时,发下面通知,告诉MobiLaunchAd,广告详情页面已经关闭
     */
    [[NSNotificationCenter defaultCenter] postNotificationName:MobiLaunchAdDetailPageDismissNotification object:nil];
    
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /**
     在广告详情控制器将要显示时,发下面通知,告诉MobiLaunchAd,广告详情页面将要显示
     */
    [[NSNotificationCenter defaultCenter] postNotificationName:MobiLaunchAdDetailPageWillShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self.progressView removeFromSuperview];
    /**
     在广告详情控制器即将销毁时,发下面通知,告诉MobiLaunchAd,广告详情页面将要关闭
     */
    [[NSNotificationCenter defaultCenter] postNotificationName:MobiLaunchAdDetailPageWillDismissNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"详情";
    self.navigationController.navigationBar.translucent = YES;
    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"←" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    
    CGFloat navbarHeight = [UIApplication sharedApplication].statusBarFrame.size.height + 44;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, navbarHeight, self.view.bounds.size.width, self.view.bounds.size.height-navbarHeight)];
    if (@available(iOS 13.0, *)) {
        self.webView.scrollView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        self.webView.scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    [self.view addSubview:self.webView];
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    if(!self.URLString) return;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:(self.URLString)]];
    [self.webView loadRequest:request];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, navbarHeight-2, self.view.bounds.size.width, 2)];
    self.progressView.progressViewStyle = UIProgressViewStyleBar;
    self.progressView.progressTintColor = [UIColor blackColor];
    [self.navigationController.view addSubview:self.progressView];
}

-(void)back{
    
    if([_webView canGoBack])
    {
        [_webView goBack];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        
        CGFloat progress = [change[NSKeyValueChangeNewKey] floatValue];
        [self.progressView setProgress:progress animated:YES];
        if(progress == 1.0)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self.progressView setProgress:0.0 animated:NO];
            });
            
            /**
             在广告详情控制器显示时,发下面通知,告诉MobiLaunchAd,广告详情页面已经展示
             */
            [[NSNotificationCenter defaultCenter] postNotificationName:MobiLaunchAdDetailPageDidShowNotification object:nil];
        }
        
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
