//
//  MEConfigConf.h
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigConf : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *rpErr;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
