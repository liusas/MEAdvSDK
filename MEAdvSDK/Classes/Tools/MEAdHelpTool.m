//
//  MEAdHelpTool.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/19.
//

#import "MEAdHelpTool.h"

@implementation MEAdHelpTool

// 获取时间戳,以天为单位
+ (NSString *)getDayStr {
    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]/60/60/24];
    return timeSp;
}
// 获取时间戳,以分为单位
+ (NSString *)getTimeStr {
    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]/60];
    return timeSp;
}

@end
