//
//  MEExpirationTimer.h
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/2.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 记录超时的计时器
@interface MEExpirationTimer : NSObject

/**
 MEExpirationTimer 初始化

 @param interval 间隔时间
 @param target 目标对象,不会造成内存泄露
 @param selector 时间点执行方法
 @param repeats 是否重复执行
 @return 返回METimer实例
 */
+ (MEExpirationTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                            target:(id)target
                          selector:(SEL)selector
                           repeats:(BOOL)repeats;

/**
 开始
 */
- (void)start;

/**
 结束
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
