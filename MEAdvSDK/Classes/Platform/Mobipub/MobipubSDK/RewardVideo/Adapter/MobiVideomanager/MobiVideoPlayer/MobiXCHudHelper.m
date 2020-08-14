//
//  XFHudHelper.m
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/10.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import "MobiXCHudHelper.h"

@implementation MobiXCHudHelper

+ (MobiXCHudHelper *)sharedInstance {
    static MobiXCHudHelper *_instance = nil;
    
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}

- (void)showHudAcitivityOnWindow{
    [self showHudAutoHideTime:3];
}

- (void)showHudAutoHideTime:(NSTimeInterval)time1 {
    if (_hud) {
        [self.hud startAnimating];
    }
    _hud = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _hud.backgroundColor = [UIColor clearColor];
    _hud.frame = UIScreen.mainScreen.bounds;
    [_hud setHidesWhenStopped:YES];
    [[[UIApplication sharedApplication] delegate].window addSubview:self.hud];
    if (time1 > 0) {
        [self hideHudAfter:time1];
    }
}

- (void)hideHud{
    [self.hud stopAnimating];
}

- (void)hideHudAfter:(NSTimeInterval)time1 {
    if (_hud) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideHud];
        });
    }
}

@end
