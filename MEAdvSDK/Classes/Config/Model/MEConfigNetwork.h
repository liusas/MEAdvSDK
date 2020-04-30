//
//  MEConfigNetwork.h
//
//  Created by 峰 刘 on 2019/11/9
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MEConfigParameter;

@interface MEConfigNetwork : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *sdk;
@property (nonatomic, strong) NSString *order;//越小优先级越高
@property (nonatomic, strong) MEConfigParameter *parameter;
@property (nonatomic, strong) NSString *name;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
