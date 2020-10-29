//
//  MobiAdNativeImg.h
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MobiAdNativeImg : NSObject

/// 图片地址
@property (nonatomic, strong) NSString *url;
/// 图片宽度
@property (nonatomic, strong) NSString *w;
/// 图片高度
@property (nonatomic, strong) NSString *h;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
