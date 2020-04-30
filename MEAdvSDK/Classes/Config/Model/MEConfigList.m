//
//  MEConfigList.m
//
//  Created by 峰 刘 on 2019/11/9
//  Copyright (c) 2019 __MyCompanyName__. All rights reserved.
//

#import "MEConfigList.h"
#import "MEConfigNetwork.h"


NSString *const kListPosid = @"posid";
NSString *const kListSortType = @"sort_type";
NSString *const kListNetwork = @"network";
NSString *const kListSortParameter = @"sort_parameter";


@interface MEConfigList ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MEConfigList

@synthesize posid = _posid;
@synthesize sortType = _sortType;
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
        self.posid = [self objectOrNilForKey:kListPosid fromDictionary:dict];
        self.sortType = [self objectOrNilForKey:kListSortType fromDictionary:dict];
        self.sortParameter = [self objectOrNilForKey:kListSortParameter fromDictionary:dict];
        NSObject *receivedNetwork = [dict objectForKey:kListNetwork];
        NSMutableArray *parsedNetwork = [NSMutableArray array];
        if ([receivedNetwork isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in (NSArray *)receivedNetwork) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [parsedNetwork addObject:[MEConfigNetwork modelObjectWithDictionary:item]];
                }
            }
        } else if ([receivedNetwork isKindOfClass:[NSDictionary class]]) {
            [parsedNetwork addObject:[MEConfigNetwork modelObjectWithDictionary:(NSDictionary *)receivedNetwork]];
        }
        
        self.network = [NSArray arrayWithArray:parsedNetwork];
        
    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.posid forKey:kListPosid];
    [mutableDict setValue:self.sortType forKey:kListSortType];
    [mutableDict setValue:self.sortParameter forKey:kListSortParameter];
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
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForNetwork] forKey:kListNetwork];

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

    self.posid = [aDecoder decodeObjectForKey:kListPosid];
    self.sortType = [aDecoder decodeObjectForKey:kListSortType];
    self.sortParameter = [aDecoder decodeObjectForKey:kListSortParameter];
    self.network = [aDecoder decodeObjectForKey:kListNetwork];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_posid forKey:kListPosid];
    [aCoder encodeObject:_sortType forKey:kListSortType];
    [aCoder encodeObject:_sortParameter forKey:kListSortParameter];
    [aCoder encodeObject:_network forKey:kListNetwork];
}

- (id)copyWithZone:(NSZone *)zone
{
    MEConfigList *copy = [[MEConfigList alloc] init];
    
    if (copy) {

        copy.posid = [self.posid copyWithZone:zone];
        copy.sortType = [self.sortType copyWithZone:zone];
        copy.sortParameter = [self.sortParameter copyWithZone:zone];
        copy.network = [self.network copyWithZone:zone];
    }
    
    return copy;
}


@end
