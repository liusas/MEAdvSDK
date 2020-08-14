//
//  MEConfigNetwork.h
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MEConfigParameter;

@interface MEConfigNetwork : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *sdk;
@property (nonatomic, strong) NSString *order;
@property (nonatomic, strong) MEConfigParameter *parameter;
@property (nonatomic, strong) NSString *name;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
