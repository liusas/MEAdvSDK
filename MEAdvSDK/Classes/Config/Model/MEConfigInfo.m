//
//  MEConfigInfo.m
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MEConfigInfo.h"


NSString *const kMEConfigInfoSdk = @"sdk";
NSString *const kMEConfigInfoAppname = @"appname";
NSString *const kMEConfigInfoAppid = @"appid";


@interface MEConfigInfo ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigInfo

@synthesize sdk = _sdk;
@synthesize appname = _appname;
@synthesize appid = _appid;


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
            self.sdk = [self objectOrNilForKey:kMEConfigInfoSdk fromDictionary:dict];
            self.appname = [self objectOrNilForKey:kMEConfigInfoAppname fromDictionary:dict];
            self.appid = [self objectOrNilForKey:kMEConfigInfoAppid fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.sdk forKey:kMEConfigInfoSdk];
    [mutableDict setValue:self.appname forKey:kMEConfigInfoAppname];
    [mutableDict setValue:self.appid forKey:kMEConfigInfoAppid];

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

    self.sdk = [aDecoder decodeObjectForKey:kMEConfigInfoSdk];
    self.appname = [aDecoder decodeObjectForKey:kMEConfigInfoAppname];
    self.appid = [aDecoder decodeObjectForKey:kMEConfigInfoAppid];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_sdk forKey:kMEConfigInfoSdk];
    [aCoder encodeObject:_appname forKey:kMEConfigInfoAppname];
    [aCoder encodeObject:_appid forKey:kMEConfigInfoAppid];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigInfo *copy = [[MEConfigInfo alloc] init];
    
    if (copy) {

        copy.sdk = [self.sdk copyWithZone:zone];
        copy.appname = [self.appname copyWithZone:zone];
        copy.appid = [self.appid copyWithZone:zone];
    }
    
    return copy;
}


@end
