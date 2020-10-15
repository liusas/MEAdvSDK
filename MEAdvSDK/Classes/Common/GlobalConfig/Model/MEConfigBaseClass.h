//
//  MEConfigBaseClass.h
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEConfigConfig.h"
#import "MEConfigNetwork.h"
#import "MEConfigParameter.h"
#import "MEConfigBaseClass.h"
#import "MEConfigConf.h"
#import "MEConfigList.h"
#import "MEConfigSdkInfo.h"
#import "MEConfigInfo.h"

@interface MEConfigBaseClass : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSArray *sdkInfo;
@property (nonatomic, strong) NSString *adAdkReqTimeout;
@property (nonatomic, strong) MEConfigConfig *config;
@property (nonatomic, strong) NSArray *list;
@property (nonatomic, strong) NSString *timeout;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
