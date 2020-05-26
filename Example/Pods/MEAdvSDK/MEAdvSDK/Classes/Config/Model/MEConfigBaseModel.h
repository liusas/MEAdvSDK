//
//  MEConfigBaseModel.h
//
//  Created by 峰 刘 on 2019/11/25
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEConfigSdkInfo.h"
#import "MEConfigInfo.h"
#import "MEConfigList.h"
#import "MEConfigNetwork.h"
#import "MEConfigParameter.h"

@interface MEConfigBaseModel : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSArray *sdkInfo;
@property (nonatomic, strong) NSString *adAdkReqTimeout;
@property (nonatomic, strong) NSArray *list;
@property (nonatomic, strong) NSString *timeout;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
