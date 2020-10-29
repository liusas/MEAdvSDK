//
//  NSDictionary+MPAdditions.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "NSDictionary+MPAdditions.h"

@implementation NSDictionary (MPAdditions)

- (NSInteger)mp_integerForKey:(id)key
{
    return [self mp_integerForKey:key defaultValue:0];
}

- (NSInteger)mp_integerForKey:(id)key defaultValue:(NSInteger)defaultVal
{
    id obj = [self objectForKey:key];
    if ([obj respondsToSelector:@selector(integerValue)]) {
        return [obj integerValue];
    }
    return defaultVal;
}

- (NSUInteger)mp_unsignedIntegerForKey:(id)key
{
    return [self mp_unsignedIntegerForKey:key defaultValue:0];
}

- (NSUInteger)mp_unsignedIntegerForKey:(id)key defaultValue:(NSUInteger)defaultVal
{
    id obj = [self objectForKey:key];
    if ([obj respondsToSelector:@selector(unsignedIntValue)]) {
        return [obj unsignedIntValue];
    }
    return defaultVal;
}

- (double)mp_doubleForKey:(id)key
{
    return [self mp_doubleForKey:key defaultValue:0.0];
}

- (double)mp_doubleForKey:(id)key defaultValue:(double)defaultVal
{
    id obj = [self objectForKey:key];
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return [obj doubleValue];
    }
    return defaultVal;
}

- (NSString *)mp_stringForKey:(id)key
{
    return [self mp_stringForKey:key defaultValue:nil];
}

- (NSString *)mp_stringForKey:(id)key defaultValue:(NSString *)defaultVal
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    return defaultVal;
}

- (BOOL)mp_boolForKey:(id)key
{
    return [self mp_boolForKey:key defaultValue:NO];
}

- (BOOL)mp_boolForKey:(id)key defaultValue:(BOOL)defaultVal
{
    id obj = [self objectForKey:key];
    if ([obj respondsToSelector:@selector(boolValue)]) {
        return [obj boolValue];
    }
    return defaultVal;
}

- (float)mp_floatForKey:(id)key
{
    return [self mp_floatForKey:key defaultValue:0];
}

- (float)mp_floatForKey:(id)key defaultValue:(float)defaultVal
{
    id obj = [self objectForKey:key];
    if ([obj respondsToSelector:@selector(floatValue)]) {
        return [obj floatValue];
    }
    return defaultVal;
}


- (BOOL)mb_toJsonSaveWithFilename:(NSString *)filename fileType:(NSString *)filetype {
    NSString *json = [self mb_turnToJsonStr];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:filetype];
    
    if (filePath != nil) {
        BOOL result = [json writeToFile:filePath atomically:YES];
        return result;
    }
    
    return NO;
}

- (NSString *)mb_turnToJsonStr {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}

@end
