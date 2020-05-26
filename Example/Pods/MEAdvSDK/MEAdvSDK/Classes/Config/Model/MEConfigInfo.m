//
//  MEConfigInfo.m
//
//  Created by 峰 刘 on 2019/11/25
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import "MEConfigInfo.h"


NSString *const kInfoSdk = @"sdk";
NSString *const kInfoAppid = @"appid";
NSString *const kInfoAppname = @"appname";


@interface MEConfigInfo ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigInfo

@synthesize sdk = _sdk;
@synthesize appid = _appid;
@synthesize appname = _appname;


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
            self.sdk = [self objectOrNilForKey:kInfoSdk fromDictionary:dict];
            self.appid = [self objectOrNilForKey:kInfoAppid fromDictionary:dict];
            self.appname = [self objectOrNilForKey:kInfoAppname fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.sdk forKey:kInfoSdk];
    [mutableDict setValue:self.appid forKey:kInfoAppid];
    [mutableDict setValue:self.appname forKey:kInfoAppname];

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

    self.sdk = [aDecoder decodeObjectForKey:kInfoSdk];
    self.appid = [aDecoder decodeObjectForKey:kInfoAppid];
    self.appname = [aDecoder decodeObjectForKey:kInfoAppname];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_sdk forKey:kInfoSdk];
    [aCoder encodeObject:_appid forKey:kInfoAppid];
    [aCoder encodeObject:_appname forKey:kInfoAppname];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigInfo *copy = [[MEConfigInfo alloc] init];
    
    if (copy) {

        copy.sdk = [self.sdk copyWithZone:zone];
        copy.appid = [self.appid copyWithZone:zone];
        copy.appname = [self.appname copyWithZone:zone];
    }
    
    return copy;
}


@end
