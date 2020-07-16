//
//  MEExpirationTimer.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/2.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "MEExpirationTimer.h"

@interface MEExpirationTimer () {
    dispatch_source_t _timer;
}
/// 间隔时长
@property (nonatomic, assign) NSTimeInterval interval;
/// 目标对象
@property (nonatomic, weak) id target;
/// 执行方法
@property (nonatomic, assign) SEL selector;
/// 是否重复执行
@property (nonatomic, assign) BOOL repeats;
/// timer是否有效
@property (nonatomic, assign) BOOL isValid;

@end

@implementation MEExpirationTimer

/**
 MEExpirationTimer 初始化
 
 @param interval 间隔时间
 @param target 目标对象,不会造成内存泄露
 @param selector 时间点执行方法
 @param repeats 是否重复执行
 @return 返回MEExpirationTimer实例
 */
+ (MEExpirationTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                            target:(id)target
                          selector:(SEL)selector
                           repeats:(BOOL)repeats {
    return [[self alloc] initWithTimeInterval:interval target:target selector:selector repeats:repeats];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                              target:(id)target
                            selector:(SEL)selector
                             repeats:(BOOL)repeats {
    if (self = [super init]) {
        _repeats = repeats;
        _interval = interval;
        _isValid = YES;
        _target = target;
        _selector = selector;
        
        __weak typeof(self) weakSelf = self;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (interval * NSEC_PER_SEC)), interval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_timer, ^{
            [weakSelf start];
        });
        dispatch_resume(_timer);
    }
    return self;
}

/**
 开始
 */
- (void)start {
    if (!_isValid) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (!self.target) {
        [self stop];
    } else {
        [self.target performSelector:_selector withObject:self];
        if (!self.repeats) {
            [self stop];
        }
    }
#pragma clang diagnostic pop
}

/**
 结束
 */
- (void)stop {
    if (_isValid) {
        dispatch_source_cancel(_timer);
        _timer = NULL;
        _target = nil;
        _isValid = NO;
    }
}

- (void)dealloc {
    [self stop];
}

@end
