//
//  NSString+MPAdditions.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "NSString+MPAdditions.h"

@implementation NSString (MPAdditions)

- (NSString *)mp_URLEncodedString {
    NSString *charactersToEscape = @"!*'();:@&=+$,/?%#[]<>";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

- (NSNumber *)safeIntegerValue {
    // Reusable number formatter since reallocating this is expensive.
    static NSNumberFormatter * formatter = nil;
    if (formatter == nil) {
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterNoStyle;
    }

    return [formatter numberFromString:self];
}

/// base64 编码
- (NSString *)encode:(NSString *)string {
    //先将string转换成data
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *base64Data = [data base64EncodedDataWithOptions:0];
    
    NSString *baseString = [[NSString alloc]initWithData:base64Data encoding:NSUTF8StringEncoding];
    
    return baseString;
}

/// base64 解码
- (NSString *)dencode:(NSString *)base64String {
    //NSData *base64data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *data = [[NSData alloc]initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    return string;
}

/// 从文件中读取 json 字符串并转成字典
/// fileType: 文件类型
- (NSDictionary *)dicFromFileWithType:(NSString *)fileType {
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *filePath = [[NSBundle mainBundle] pathForResource:self ofType:fileType];
    NSData * data = [NSData dataWithContentsOfFile:filePath];
    NSString * chapterContent = @"";
    BOOL lossy = NO;
    NSArray * enccList = @[@(NSUTF8StringEncoding),@(enc)];
    NSStringEncoding encc = [NSString stringEncodingForData:data
                                            encodingOptions:@{NSStringEncodingDetectionSuggestedEncodingsKey:enccList}
                                            convertedString:&chapterContent  usedLossyConversion:&lossy];

    NSData * resData = [[NSData alloc]initWithData:[chapterContent dataUsingEncoding:NSUTF8StringEncoding]];
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableLeaves error:nil];
    return responseObject;
}

@end
