//
//  MEConfigBaseClass.m
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MEConfigBaseClass.h"
#import "MEConfigSdkInfo.h"
#import "MEConfigConfig.h"
#import "MEConfigList.h"


NSString *const kMEConfigBaseClassSdkInfo = @"sdk_info";
NSString *const kMEConfigBaseClassAdAdkReqTimeout = @"ad_adk_req_timeout";
NSString *const kMEConfigBaseClassConfig = @"config";
NSString *const kMEConfigBaseClassList = @"list";
NSString *const kMEConfigBaseClassTimeout = @"timeout";


@interface MEConfigBaseClass ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigBaseClass

@synthesize sdkInfo = _sdkInfo;
@synthesize adAdkReqTimeout = _adAdkReqTimeout;
@synthesize config = _config;
@synthesize list = _list;
@synthesize timeout = _timeout;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    
    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
    NSObject *receivedMEConfigSdkInfo = [dict objectForKey:kMEConfigBaseClassSdkInfo];
    NSMutableArray *parsedMEConfigSdkInfo = [NSMutableArray array];
    if ([receivedMEConfigSdkInfo isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedMEConfigSdkInfo) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedMEConfigSdkInfo addObject:[MEConfigSdkInfo modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedMEConfigSdkInfo isKindOfClass:[NSDictionary class]]) {
       [parsedMEConfigSdkInfo addObject:[MEConfigSdkInfo modelObjectWithDictionary:(NSDictionary *)receivedMEConfigSdkInfo]];
    }

    self.sdkInfo = [NSArray arrayWithArray:parsedMEConfigSdkInfo];
            self.adAdkReqTimeout = [self objectOrNilForKey:kMEConfigBaseClassAdAdkReqTimeout fromDictionary:dict];
            self.config = [MEConfigConfig modelObjectWithDictionary:[dict objectForKey:kMEConfigBaseClassConfig]];
    NSObject *receivedMEConfigList = [dict objectForKey:kMEConfigBaseClassList];
    NSMutableArray *parsedMEConfigList = [NSMutableArray array];
    if ([receivedMEConfigList isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedMEConfigList) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedMEConfigList addObject:[MEConfigList modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedMEConfigList isKindOfClass:[NSDictionary class]]) {
       [parsedMEConfigList addObject:[MEConfigList modelObjectWithDictionary:(NSDictionary *)receivedMEConfigList]];
    }

    self.list = [NSArray arrayWithArray:parsedMEConfigList];
            self.timeout = [self objectOrNilForKey:kMEConfigBaseClassTimeout fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    NSMutableArray *tempArrayForSdkInfo = [NSMutableArray array];
    for (NSObject *subArrayObject in self.sdkInfo) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForSdkInfo addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForSdkInfo addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForSdkInfo] forKey:kMEConfigBaseClassSdkInfo];
    [mutableDict setValue:self.adAdkReqTimeout forKey:kMEConfigBaseClassAdAdkReqTimeout];
    [mutableDict setValue:[self.config dictionaryRepresentation] forKey:kMEConfigBaseClassConfig];
    NSMutableArray *tempArrayForList = [NSMutableArray array];
    for (NSObject *subArrayObject in self.list) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForList addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForList addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForList] forKey:kMEConfigBaseClassList];
    [mutableDict setValue:self.timeout forKey:kMEConfigBaseClassTimeout];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.sdkInfo = [aDecoder decodeObjectForKey:kMEConfigBaseClassSdkInfo];
    self.adAdkReqTimeout = [aDecoder decodeObjectForKey:kMEConfigBaseClassAdAdkReqTimeout];
    self.config = [aDecoder decodeObjectForKey:kMEConfigBaseClassConfig];
    self.list = [aDecoder decodeObjectForKey:kMEConfigBaseClassList];
    self.timeout = [aDecoder decodeObjectForKey:kMEConfigBaseClassTimeout];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_sdkInfo forKey:kMEConfigBaseClassSdkInfo];
    [aCoder encodeObject:_adAdkReqTimeout forKey:kMEConfigBaseClassAdAdkReqTimeout];
    [aCoder encodeObject:_config forKey:kMEConfigBaseClassConfig];
    [aCoder encodeObject:_list forKey:kMEConfigBaseClassList];
    [aCoder encodeObject:_timeout forKey:kMEConfigBaseClassTimeout];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigBaseClass *copy = [[MEConfigBaseClass alloc] init];
    
    if (copy) {

        copy.sdkInfo = [self.sdkInfo copyWithZone:zone];
        copy.adAdkReqTimeout = [self.adAdkReqTimeout copyWithZone:zone];
        copy.config = [self.config copyWithZone:zone];
        copy.list = [self.list copyWithZone:zone];
        copy.timeout = [self.timeout copyWithZone:zone];
    }
    
    return copy;
}


@end
