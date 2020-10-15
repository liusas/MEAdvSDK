//
//  UIColor+BaseFramework.h
//  MEPedometer
//
//  Created by 刘峰 on 2019/10/9.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (MobiBaseFramework)
// Convert hexadecimal value to RGB
+ (UIColor *)colorWithHex:(UInt32)hexadecimal;
+ (UIColor *)colorWithHexString:(NSString *)hexadecimal;

// Convert hexadecimal value to RGB
// format:
//	0x = Hexadecimal specifier (# for strings)
//	ff = alpha, ff = red, ff = green, ff = blue
+ (UIColor *)colorWithAlphaHex:(UInt32)hexadecimal;
+ (UIColor *)colorWithAlphaHexString:(NSString *)hexadecimal;

// Return the hexadecimal value of the RGB color specified.
+ (NSString *)hexStringFromColor: (UIColor *)color;

// Generates a color randomly
+ (UIColor *)randomColor;

// ObjC (manual hex conversion to RGB)
+ (UIColor *)colorWithHexa:(NSString *)hexadecimal;

+ (UIColor *)colorSetWithRGB:(unsigned int)red
                       green:(unsigned int)green
                        blue:(unsigned int)blue
                       alpha:(float)alpha;
@end
