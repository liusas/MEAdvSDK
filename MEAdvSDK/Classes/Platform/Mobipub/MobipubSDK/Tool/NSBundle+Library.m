//
//  NSBundle+Library.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2020/1/6.
//

#import "NSBundle+Library.h"

@implementation NSBundle (Library)

+ (NSBundle *)myLibraryBundle {
    return [self bundleWithURL:[self myLibraryBundleURL]];
}


+ (NSURL *)myLibraryBundleURL {
    NSBundle *bundle = [NSBundle bundleForClass:self];
    return [bundle URLForResource:@"MobiPubSDK" withExtension:@"bundle"];
}

@end
