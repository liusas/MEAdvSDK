//
//  MEConfigSdkInfo.m
//
//  Created by 峰 刘 on 2019/11/25
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import "MEConfigSdkInfo.h"
#import "MEConfigInfo.h"


NSString *const kMEConfigSdkInfoMid = @"mid";
NSString *const kMEConfigSdkInfo = @"info";


@interface MEConfigSdkInfo ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigSdkInfo

@synthesize mid = _mid;
@synthesize info = _info;


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
            self.mid = [self objectOrNilForKey:kMEConfigSdkInfoMid fromDictionary:dict];
    NSObject *receivedInfo = [dict objectForKey:kMEConfigSdkInfo];
    NSMutableArray *parsedInfo = [NSMutableArray array];
    if ([receivedInfo isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedInfo) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedInfo addObject:[MEConfigInfo modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedInfo isKindOfClass:[NSDictionary class]]) {
       [parsedInfo addObject:[MEConfigInfo modelObjectWithDictionary:(NSDictionary *)receivedInfo]];
    }

    self.info = [NSArray arrayWithArray:parsedInfo];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.mid forKey:kMEConfigSdkInfoMid];
    NSMutableArray *tempArrayForInfo = [NSMutableArray array];
    for (NSObject *subArrayObject in self.info) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForInfo addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForInfo addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForInfo] forKey:kMEConfigSdkInfo];

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

    self.mid = [aDecoder decodeObjectForKey:kMEConfigSdkInfoMid];
    self.info = [aDecoder decodeObjectForKey:kMEConfigSdkInfo];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_mid forKey:kMEConfigSdkInfoMid];
    [aCoder encodeObject:_info forKey:kMEConfigSdkInfo];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigSdkInfo *copy = [[MEConfigSdkInfo alloc] init];
    
    if (copy) {

        copy.mid = [self.mid copyWithZone:zone];
        copy.info = [self.info copyWithZone:zone];
    }
    
    return copy;
}


@end
