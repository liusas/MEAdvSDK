//
//  Info.h
//
//  Created by 峰 刘 on 2019/11/25
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigInfo : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *sdk;
@property (nonatomic, strong) NSString *appid;
@property (nonatomic, strong) NSString *appname;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
