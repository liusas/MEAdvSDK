//
//  MEConfigParameter.m
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MEConfigParameter.h"


NSString *const kMEConfigParameterPosid = @"posid";
NSString *const kMEConfigParameterAppname = @"appname";
NSString *const kMEConfigParameterAppid = @"appid";


@interface MEConfigParameter ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigParameter

@synthesize posid = _posid;
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
            self.posid = [self objectOrNilForKey:kMEConfigParameterPosid fromDictionary:dict];
            self.appname = [self objectOrNilForKey:kMEConfigParameterAppname fromDictionary:dict];
            self.appid = [self objectOrNilForKey:kMEConfigParameterAppid fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.posid forKey:kMEConfigParameterPosid];
    [mutableDict setValue:self.appname forKey:kMEConfigParameterAppname];
    [mutableDict setValue:self.appid forKey:kMEConfigParameterAppid];

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

    self.posid = [aDecoder decodeObjectForKey:kMEConfigParameterPosid];
    self.appname = [aDecoder decodeObjectForKey:kMEConfigParameterAppname];
    self.appid = [aDecoder decodeObjectForKey:kMEConfigParameterAppid];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_posid forKey:kMEConfigParameterPosid];
    [aCoder encodeObject:_appname forKey:kMEConfigParameterAppname];
    [aCoder encodeObject:_appid forKey:kMEConfigParameterAppid];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigParameter *copy = [[MEConfigParameter alloc] init];
    
    if (copy) {

        copy.posid = [self.posid copyWithZone:zone];
        copy.appname = [self.appname copyWithZone:zone];
        copy.appid = [self.appid copyWithZone:zone];
    }
    
    return copy;
}


@end
