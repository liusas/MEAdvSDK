//
//  MEConfigParameter.h
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigParameter : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *posid;
@property (nonatomic, strong) NSString *appname;
@property (nonatomic, strong) NSString *appid;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
