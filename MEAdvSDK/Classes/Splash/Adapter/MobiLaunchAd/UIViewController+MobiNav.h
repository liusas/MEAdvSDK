//
//  UIViewController+MobiNav.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/7/9.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (MobiNav)

@property(nonatomic,strong,readonly) UINavigationController *mobiNavigationController;

@end

NS_ASSUME_NONNULL_END
