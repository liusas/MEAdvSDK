//
//  NSDate+MPAdditions.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "NSDate+MPAdditions.h"

@implementation NSDate (MPAdditions)

+ (NSDate *)now {
    return [NSDate date];
}

/// 获取毫秒时间戳
+(NSString *)getNowTimeMillionsecond {

    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式

    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];

    return timeSp;
}

@end
