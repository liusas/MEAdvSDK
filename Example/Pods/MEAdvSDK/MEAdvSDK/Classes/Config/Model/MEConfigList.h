//
//  MEConfigList.h
//
//  Created by 峰 刘 on 2019/11/9
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigList : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *posid;
@property (nonatomic, strong) NSString *sortType;
@property (nonatomic, strong) NSArray *network;
@property (nonatomic, strong) NSArray *sortParameter;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
