//
//  MEConfigConfig.h
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigConfig : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *developerUrl;
@property (nonatomic, strong) NSString *adAdkReqTimeout;
@property (nonatomic, strong) NSString *reportUrl;
@property (nonatomic, strong) NSString *timeout;
@property (nonatomic, strong) NSString *protoUrl;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
