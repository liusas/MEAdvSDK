//
//  MEConfigNetwork.m
//
//  Created by 峰 刘 on 2019/11/9
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import "MEConfigNetwork.h"
#import "MEConfigParameter.h"


NSString *const kNetworkSdk = @"sdk";
NSString *const kNetworkOrder = @"order";
NSString *const kNetworkParameter = @"parameter";
NSString *const kNetworkName = @"name";


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
            self.sdk = [self objectOrNilForKey:kNetworkSdk fromDictionary:dict];
            self.order = [self objectOrNilForKey:kNetworkOrder fromDictionary:dict];
            self.parameter = [MEConfigParameter modelObjectWithDictionary:[dict objectForKey:kNetworkParameter]];
            self.name = [self objectOrNilForKey:kNetworkName fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.sdk forKey:kNetworkSdk];
    [mutableDict setValue:self.order forKey:kNetworkOrder];
    [mutableDict setValue:[self.parameter dictionaryRepresentation] forKey:kNetworkParameter];
    [mutableDict setValue:self.name forKey:kNetworkName];

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

    self.sdk = [aDecoder decodeObjectForKey:kNetworkSdk];
    self.order = [aDecoder decodeObjectForKey:kNetworkOrder];
    self.parameter = [aDecoder decodeObjectForKey:kNetworkParameter];
    self.name = [aDecoder decodeObjectForKey:kNetworkName];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_sdk forKey:kNetworkSdk];
    [aCoder encodeObject:_order forKey:kNetworkOrder];
    [aCoder encodeObject:_parameter forKey:kNetworkParameter];
    [aCoder encodeObject:_name forKey:kNetworkName];
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
