//
//  MobiLaunchAdButton.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  倒计时类型
 */
typedef NS_ENUM(NSInteger,MobiSkipType) {
    MobiSkipTypeNone      = 1,//无
    /** 方形 */
    MobiSkipTypeTime      = 2,//方形:倒计时
    MobiSkipTypeText      = 3,//方形:跳过
    MobiSkipTypeTimeText  = 4,//方形:倒计时+跳过 (default)
    /** 圆形 */
    MobiSkipTypeRoundTime = 5,//圆形:倒计时
    MobiSkipTypeRoundText = 6,//圆形:跳过
    MobiSkipTypeRoundProgressTime = 7,//圆形:进度圈+倒计时
    MobiSkipTypeRoundProgressText = 8,//圆形:进度圈+跳过
};

@interface MobiVideoAdButton : UIButton

- (instancetype)init;
- (instancetype)initWithSkipType:(MobiSkipType)skipType;
- (void)startRoundDispathTimerWithDuration:(CGFloat)duration;
- (void)setTitleWithSkipType:(MobiSkipType)skipType duration:(NSInteger)duration;

@end

NS_ASSUME_NONNULL_END
