//
//  MEConfigList.h
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MEConfigConf;

@interface MEConfigList : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *posid;
@property (nonatomic, strong) NSString *showtype;
@property (nonatomic, strong) NSString *sortType;
@property (nonatomic, strong) MEConfigConf *conf;
@property (nonatomic, strong) NSArray *sortParameter;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *network;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
