//
//  UIViewController+MobiNav.m
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/7/9.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "UIViewController+MobiNav.h"

@implementation UIViewController (MobiNav)

- (UINavigationController*)mobiNavigationController
{
    UINavigationController* nav = nil;
    if ([self isKindOfClass:[UINavigationController class]]) {
        nav = (id)self;
    }
    else {
        if ([self isKindOfClass:[UITabBarController class]]) {
            nav = ((UITabBarController*)self).selectedViewController.mobiNavigationController;
        }
        else {
            nav = self.navigationController;
        }
    }
    return nav;
}

@end
