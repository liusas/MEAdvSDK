//
//  MEConfigSdkInfo.m
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MEConfigSdkInfo.h"
#import "MEConfigInfo.h"


NSString *const kMEConfigSdkInfoMid = @"mid";
NSString *const kMEConfigSdkInfoInfo = @"info";


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
    NSObject *receivedMEConfigInfo = [dict objectForKey:kMEConfigSdkInfoInfo];
    NSMutableArray *parsedMEConfigInfo = [NSMutableArray array];
    if ([receivedMEConfigInfo isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedMEConfigInfo) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedMEConfigInfo addObject:[MEConfigInfo modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedMEConfigInfo isKindOfClass:[NSDictionary class]]) {
       [parsedMEConfigInfo addObject:[MEConfigInfo modelObjectWithDictionary:(NSDictionary *)receivedMEConfigInfo]];
    }

    self.info = [NSArray arrayWithArray:parsedMEConfigInfo];

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
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForInfo] forKey:kMEConfigSdkInfoInfo];

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
    self.info = [aDecoder decodeObjectForKey:kMEConfigSdkInfoInfo];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_mid forKey:kMEConfigSdkInfoMid];
    [aCoder encodeObject:_info forKey:kMEConfigSdkInfoInfo];
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
