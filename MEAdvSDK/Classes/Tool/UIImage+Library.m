//
//  UIImage+Library.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/1/6.
//

#import "UIImage+Library.h"
#import "NSBundle+Library.h"

@implementation UIImage (Library)

+ (UIImage *)bundleImageNamed:(NSString *)name {
    return [self imageNamed:name inBundle:[NSBundle myLibraryBundle]];
}

+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
    NSInteger scale = [[UIScreen mainScreen] scale];
    NSString *imgName = [NSString stringWithFormat:@"%@@%zdx.png", name,scale];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
    return [UIImage imageNamed:imgName inBundle:bundle compatibleWithTraitCollection:nil];
#elif __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    return [UIImage imageWithContentsOfFile:[bundle pathForResource:imgName ofType:nil]];
#else
    if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        return [UIImage imageNamed:imgName inBundle:bundle compatibleWithTraitCollection:nil];
    } else {
        return [UIImage imageWithContentsOfFile:[bundle pathForResource:imgName ofType:nil]];
    }
#endif
}

@end
