//
//  MEConfigList.m
//
//  Created by 峰 刘 on 2020/7/3
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MEConfigList.h"
#import "MEConfigConf.h"
#import "MEConfigNetwork.h"


NSString *const kMEConfigListPosid = @"posid";
NSString *const kMEConfigListShowtype = @"showtype";
NSString *const kMEConfigListSortType = @"sort_type";
NSString *const kMEConfigListConf = @"conf";
NSString *const kMEConfigListSortParameter = @"sort_parameter";
NSString *const kMEConfigListName = @"name";
NSString *const kMEConfigListNetwork = @"network";


@interface MEConfigList ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigList

@synthesize posid = _posid;
@synthesize showtype = _showtype;
@synthesize sortType = _sortType;
@synthesize conf = _conf;
@synthesize sortParameter = _sortParameter;
@synthesize name = _name;
@synthesize network = _network;


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
            self.posid = [self objectOrNilForKey:kMEConfigListPosid fromDictionary:dict];
            self.showtype = [self objectOrNilForKey:kMEConfigListShowtype fromDictionary:dict];
            self.sortType = [self objectOrNilForKey:kMEConfigListSortType fromDictionary:dict];
            self.conf = [MEConfigConf modelObjectWithDictionary:[dict objectForKey:kMEConfigListConf]];
            self.sortParameter = [self objectOrNilForKey:kMEConfigListSortParameter fromDictionary:dict];
            self.name = [self objectOrNilForKey:kMEConfigListName fromDictionary:dict];
    NSObject *receivedMEConfigNetwork = [dict objectForKey:kMEConfigListNetwork];
    NSMutableArray *parsedMEConfigNetwork = [NSMutableArray array];
    if ([receivedMEConfigNetwork isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedMEConfigNetwork) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedMEConfigNetwork addObject:[MEConfigNetwork modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedMEConfigNetwork isKindOfClass:[NSDictionary class]]) {
       [parsedMEConfigNetwork addObject:[MEConfigNetwork modelObjectWithDictionary:(NSDictionary *)receivedMEConfigNetwork]];
    }

    self.network = [NSArray arrayWithArray:parsedMEConfigNetwork];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.posid forKey:kMEConfigListPosid];
    [mutableDict setValue:self.showtype forKey:kMEConfigListShowtype];
    [mutableDict setValue:self.sortType forKey:kMEConfigListSortType];
    [mutableDict setValue:[self.conf dictionaryRepresentation] forKey:kMEConfigListConf];
    NSMutableArray *tempArrayForSortParameter = [NSMutableArray array];
    for (NSObject *subArrayObject in self.sortParameter) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForSortParameter addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForSortParameter addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForSortParameter] forKey:kMEConfigListSortParameter];
    [mutableDict setValue:self.name forKey:kMEConfigListName];
    NSMutableArray *tempArrayForNetwork = [NSMutableArray array];
    for (NSObject *subArrayObject in self.network) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForNetwork addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForNetwork addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForNetwork] forKey:kMEConfigListNetwork];

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

    self.posid = [aDecoder decodeObjectForKey:kMEConfigListPosid];
    self.showtype = [aDecoder decodeObjectForKey:kMEConfigListShowtype];
    self.sortType = [aDecoder decodeObjectForKey:kMEConfigListSortType];
    self.conf = [aDecoder decodeObjectForKey:kMEConfigListConf];
    self.sortParameter = [aDecoder decodeObjectForKey:kMEConfigListSortParameter];
    self.name = [aDecoder decodeObjectForKey:kMEConfigListName];
    self.network = [aDecoder decodeObjectForKey:kMEConfigListNetwork];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_posid forKey:kMEConfigListPosid];
    [aCoder encodeObject:_showtype forKey:kMEConfigListShowtype];
    [aCoder encodeObject:_sortType forKey:kMEConfigListSortType];
    [aCoder encodeObject:_conf forKey:kMEConfigListConf];
    [aCoder encodeObject:_sortParameter forKey:kMEConfigListSortParameter];
    [aCoder encodeObject:_name forKey:kMEConfigListName];
    [aCoder encodeObject:_network forKey:kMEConfigListNetwork];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigList *copy = [[MEConfigList alloc] init];
    
    if (copy) {

        copy.posid = [self.posid copyWithZone:zone];
        copy.showtype = [self.showtype copyWithZone:zone];
        copy.sortType = [self.sortType copyWithZone:zone];
        copy.conf = [self.conf copyWithZone:zone];
        copy.sortParameter = [self.sortParameter copyWithZone:zone];
        copy.name = [self.name copyWithZone:zone];
        copy.network = [self.network copyWithZone:zone];
    }
    
    return copy;
}


@end
