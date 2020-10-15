//
//  XCHudHelper.h
//
//  Created by TopDev on 10/23/14.
//  Copyright (c) 2014 TopDev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MobiXCHudHelper : NSObject

@property(nonatomic, strong) UIActivityIndicatorView *hud;

// 单例
+ (MobiXCHudHelper *)sharedInstance;

// 在window上显示菊花转hud
- (void)showHudAcitivityOnWindow;

// 在window上显示hud
- (void)showHudAutoHideTime:(NSTimeInterval)time1;

// 隐藏hud
- (void)hideHud;

- (void)hideHudAfter:(NSTimeInterval)time;


@end
