//
//  MEConfigBaseModel.m
//
//  Created by 峰 刘 on 2019/11/25
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import "MEConfigBaseModel.h"
#import "MEConfigSdkInfo.h"
#import "MEConfigList.h"


NSString *const kMEConfigBaseModelSdkInfo = @"sdk_info";
NSString *const kMEConfigBaseModelAdAdkReqTimeout = @"ad_adk_req_timeout";
NSString *const kMEConfigBaseModelList = @"list";
NSString *const kMEConfigBaseModelTimeout = @"timeout";


@interface MEConfigBaseModel ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigBaseModel

@synthesize sdkInfo = _sdkInfo;
@synthesize adAdkReqTimeout = _adAdkReqTimeout;
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
    NSObject *receivedSdkInfo = [dict objectForKey:kMEConfigBaseModelSdkInfo];
    NSMutableArray *parsedSdkInfo = [NSMutableArray array];
    if ([receivedSdkInfo isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedSdkInfo) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedSdkInfo addObject:[MEConfigSdkInfo modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedSdkInfo isKindOfClass:[NSDictionary class]]) {
       [parsedSdkInfo addObject:[MEConfigSdkInfo modelObjectWithDictionary:(NSDictionary *)receivedSdkInfo]];
    }

    self.sdkInfo = [NSArray arrayWithArray:parsedSdkInfo];
            self.adAdkReqTimeout = [self objectOrNilForKey:kMEConfigBaseModelAdAdkReqTimeout fromDictionary:dict];
    NSObject *receivedList = [dict objectForKey:kMEConfigBaseModelList];
    NSMutableArray *parsedList = [NSMutableArray array];
    if ([receivedList isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedList) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedList addObject:[MEConfigList modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedList isKindOfClass:[NSDictionary class]]) {
       [parsedList addObject:[MEConfigList modelObjectWithDictionary:(NSDictionary *)receivedList]];
    }

    self.list = [NSArray arrayWithArray:parsedList];
            self.timeout = [self objectOrNilForKey:kMEConfigBaseModelTimeout fromDictionary:dict];

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
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForSdkInfo] forKey:kMEConfigBaseModelSdkInfo];
    [mutableDict setValue:self.adAdkReqTimeout forKey:kMEConfigBaseModelAdAdkReqTimeout];
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
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForList] forKey:kMEConfigBaseModelList];
    [mutableDict setValue:self.timeout forKey:kMEConfigBaseModelTimeout];

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

    self.sdkInfo = [aDecoder decodeObjectForKey:kMEConfigBaseModelSdkInfo];
    self.adAdkReqTimeout = [aDecoder decodeObjectForKey:kMEConfigBaseModelAdAdkReqTimeout];
    self.list = [aDecoder decodeObjectForKey:kMEConfigBaseModelList];
    self.timeout = [aDecoder decodeObjectForKey:kMEConfigBaseModelTimeout];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_sdkInfo forKey:kMEConfigBaseModelSdkInfo];
    [aCoder encodeObject:_adAdkReqTimeout forKey:kMEConfigBaseModelAdAdkReqTimeout];
    [aCoder encodeObject:_list forKey:kMEConfigBaseModelList];
    [aCoder encodeObject:_timeout forKey:kMEConfigBaseModelTimeout];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigBaseModel *copy = [[MEConfigBaseModel alloc] init];
    
    if (copy) {

        copy.sdkInfo = [self.sdkInfo copyWithZone:zone];
        copy.adAdkReqTimeout = [self.adAdkReqTimeout copyWithZone:zone];
        copy.list = [self.list copyWithZone:zone];
        copy.timeout = [self.timeout copyWithZone:zone];
    }
    
    return copy;
}


@end
