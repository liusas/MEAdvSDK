//
//  MEConfigConfig.m
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MEConfigConfig.h"


NSString *const kMEConfigConfigDeveloperUrl = @"developer_url";
NSString *const kMEConfigConfigAdAdkReqTimeout = @"ad_adk_req_timeout";
NSString *const kMEConfigConfigReportUrl = @"report_url";
NSString *const kMEConfigConfigTimeout = @"timeout";
NSString *const kMEConfigConfigProtoUrl = @"proto_url";


@interface MEConfigConfig ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigConfig

@synthesize developerUrl = _developerUrl;
@synthesize adAdkReqTimeout = _adAdkReqTimeout;
@synthesize reportUrl = _reportUrl;
@synthesize timeout = _timeout;
@synthesize protoUrl = _protoUrl;


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
            self.developerUrl = [self objectOrNilForKey:kMEConfigConfigDeveloperUrl fromDictionary:dict];
            self.adAdkReqTimeout = [self objectOrNilForKey:kMEConfigConfigAdAdkReqTimeout fromDictionary:dict];
            self.reportUrl = [self objectOrNilForKey:kMEConfigConfigReportUrl fromDictionary:dict];
            self.timeout = [self objectOrNilForKey:kMEConfigConfigTimeout fromDictionary:dict];
            self.protoUrl = [self objectOrNilForKey:kMEConfigConfigProtoUrl fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.developerUrl forKey:kMEConfigConfigDeveloperUrl];
    [mutableDict setValue:self.adAdkReqTimeout forKey:kMEConfigConfigAdAdkReqTimeout];
    [mutableDict setValue:self.reportUrl forKey:kMEConfigConfigReportUrl];
    [mutableDict setValue:self.timeout forKey:kMEConfigConfigTimeout];
    [mutableDict setValue:self.protoUrl forKey:kMEConfigConfigProtoUrl];

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

    self.developerUrl = [aDecoder decodeObjectForKey:kMEConfigConfigDeveloperUrl];
    self.adAdkReqTimeout = [aDecoder decodeObjectForKey:kMEConfigConfigAdAdkReqTimeout];
    self.reportUrl = [aDecoder decodeObjectForKey:kMEConfigConfigReportUrl];
    self.timeout = [aDecoder decodeObjectForKey:kMEConfigConfigTimeout];
    self.protoUrl = [aDecoder decodeObjectForKey:kMEConfigConfigProtoUrl];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_developerUrl forKey:kMEConfigConfigDeveloperUrl];
    [aCoder encodeObject:_adAdkReqTimeout forKey:kMEConfigConfigAdAdkReqTimeout];
    [aCoder encodeObject:_reportUrl forKey:kMEConfigConfigReportUrl];
    [aCoder encodeObject:_timeout forKey:kMEConfigConfigTimeout];
    [aCoder encodeObject:_protoUrl forKey:kMEConfigConfigProtoUrl];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigConfig *copy = [[MEConfigConfig alloc] init];
    
    if (copy) {

        copy.developerUrl = [self.developerUrl copyWithZone:zone];
        copy.adAdkReqTimeout = [self.adAdkReqTimeout copyWithZone:zone];
        copy.reportUrl = [self.reportUrl copyWithZone:zone];
        copy.timeout = [self.timeout copyWithZone:zone];
        copy.protoUrl = [self.protoUrl copyWithZone:zone];
    }
    
    return copy;
}


@end
