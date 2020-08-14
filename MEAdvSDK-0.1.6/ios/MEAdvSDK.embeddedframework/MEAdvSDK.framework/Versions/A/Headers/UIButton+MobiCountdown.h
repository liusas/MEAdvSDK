//
//  UIButton+Countdown.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/31.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (MobiCountdown)
/**
 *  倒计时按钮
 *
 *  @param timeLine 倒计时总时间
 *  @param title    还没倒计时的title
 *  @param subTitle 倒计时中的子名字，如时、分
 */
- (void)startWithTime:(NSInteger)timeLine title:(NSString *)title countDownTitle:(NSString *)subTitle mainColor:(unsigned int)mainHex countColor:(unsigned int)countHex;
@end

NS_ASSUME_NONNULL_END
