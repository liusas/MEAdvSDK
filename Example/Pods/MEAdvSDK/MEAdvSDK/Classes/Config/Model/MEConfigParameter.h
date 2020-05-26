//
//  MEConfigParameter.h
//
//  Created by 峰 刘 on 2019/11/9
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigParameter : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *appid;
@property (nonatomic, strong) NSString *appname;
@property (nonatomic, strong) NSString *posid;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
