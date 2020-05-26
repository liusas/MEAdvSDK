//
//  MEConfigSdkInfo.h
//
//  Created by 峰 刘 on 2019/11/25
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MEConfigSdkInfo : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *mid;
@property (nonatomic, strong) NSArray *info;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
