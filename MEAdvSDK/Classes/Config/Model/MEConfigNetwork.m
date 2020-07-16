//
//  MEConfigNetwork.m
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MEConfigNetwork.h"
#import "MEConfigParameter.h"


NSString *const kMEConfigNetworkSdk = @"sdk";
NSString *const kMEConfigNetworkOrder = @"order";
NSString *const kMEConfigNetworkParameter = @"parameter";
NSString *const kMEConfigNetworkName = @"name";


@interface MEConfigNetwork ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigNetwork

@synthesize sdk = _sdk;
@synthesize order = _order;
@synthesize parameter = _parameter;
@synthesize name = _name;


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
            self.sdk = [self objectOrNilForKey:kMEConfigNetworkSdk fromDictionary:dict];
            self.order = [self objectOrNilForKey:kMEConfigNetworkOrder fromDictionary:dict];
            self.parameter = [MEConfigParameter modelObjectWithDictionary:[dict objectForKey:kMEConfigNetworkParameter]];
            self.name = [self objectOrNilForKey:kMEConfigNetworkName fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.sdk forKey:kMEConfigNetworkSdk];
    [mutableDict setValue:self.order forKey:kMEConfigNetworkOrder];
    [mutableDict setValue:[self.parameter dictionaryRepresentation] forKey:kMEConfigNetworkParameter];
    [mutableDict setValue:self.name forKey:kMEConfigNetworkName];

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

    self.sdk = [aDecoder decodeObjectForKey:kMEConfigNetworkSdk];
    self.order = [aDecoder decodeObjectForKey:kMEConfigNetworkOrder];
    self.parameter = [aDecoder decodeObjectForKey:kMEConfigNetworkParameter];
    self.name = [aDecoder decodeObjectForKey:kMEConfigNetworkName];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_sdk forKey:kMEConfigNetworkSdk];
    [aCoder encodeObject:_order forKey:kMEConfigNetworkOrder];
    [aCoder encodeObject:_parameter forKey:kMEConfigNetworkParameter];
    [aCoder encodeObject:_name forKey:kMEConfigNetworkName];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigNetwork *copy = [[MEConfigNetwork alloc] init];
    
    if (copy) {

        copy.sdk = [self.sdk copyWithZone:zone];
        copy.order = [self.order copyWithZone:zone];
        copy.parameter = [self.parameter copyWithZone:zone];
        copy.name = [self.name copyWithZone:zone];
    }
    
    return copy;
}


@end
