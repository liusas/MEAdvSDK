//
//  MEConfigParameter.m
//
//  Created by 峰 刘 on 2019/11/9
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import "MEConfigParameter.h"


NSString *const kParameterAppid = @"appid";
NSString *const kParameterAppname = @"appname";
NSString *const kParameterPosid = @"posid";


@interface MEConfigParameter ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigParameter

@synthesize appid = _appid;
@synthesize appname = _appname;
@synthesize posid = _posid;


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
            self.appid = [self objectOrNilForKey:kParameterAppid fromDictionary:dict];
            self.appname = [self objectOrNilForKey:kParameterAppname fromDictionary:dict];
            self.posid = [self objectOrNilForKey:kParameterPosid fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.appid forKey:kParameterAppid];
    [mutableDict setValue:self.appname forKey:kParameterAppname];
    [mutableDict setValue:self.posid forKey:kParameterPosid];

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

    self.appid = [aDecoder decodeObjectForKey:kParameterAppid];
    self.appname = [aDecoder decodeObjectForKey:kParameterAppname];
    self.posid = [aDecoder decodeObjectForKey:kParameterPosid];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_appid forKey:kParameterAppid];
    [aCoder encodeObject:_appname forKey:kParameterAppname];
    [aCoder encodeObject:_posid forKey:kParameterPosid];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigParameter *copy = [[MEConfigParameter alloc] init];
    
    if (copy) {

        copy.appid = [self.appid copyWithZone:zone];
        copy.appname = [self.appname copyWithZone:zone];
        copy.posid = [self.posid copyWithZone:zone];
    }
    
    return copy;
}


@end
