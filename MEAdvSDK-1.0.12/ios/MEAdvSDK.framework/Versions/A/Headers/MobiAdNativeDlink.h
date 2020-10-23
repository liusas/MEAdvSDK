//
//  MobiAdNativeDlink.h
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MobiAdNativeDlink : NSObject

/// deeplink地址
@property (nonatomic, strong) NSString *durl;
/// deeplink下载地址
@property (nonatomic, strong) NSString *wurl;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
