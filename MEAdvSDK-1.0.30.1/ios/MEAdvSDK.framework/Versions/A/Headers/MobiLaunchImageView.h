//
//  MobiLaunchImageView.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/28.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/** 启动图来源 */
typedef NS_ENUM(NSInteger,MobiSourceType) {
    /** LaunchScreen.storyboard(default) */
    MobiSourceTypeLaunchScreen = 1,
    /** LaunchImage */
    MobiSourceTypeLaunchImage = 2,
};

@interface MobiLaunchImageView : UIImageView

- (instancetype)initWithSourceType:(MobiSourceType)sourceType;

@end

NS_ASSUME_NONNULL_END
