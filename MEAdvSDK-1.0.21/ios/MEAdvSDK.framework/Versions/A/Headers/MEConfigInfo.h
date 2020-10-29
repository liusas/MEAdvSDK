//
//  MEConfigInfo.h
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigInfo : NSObject <NSCoding, NSCopying>

// 广告平台的名字,建议字母
@property (nonatomic, strong) NSString *sdk;
// 对应的平台名称
@property (nonatomic, strong) NSString *appname;
// 平台初始化用的 appid
@property (nonatomic, strong) NSString *appid;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
