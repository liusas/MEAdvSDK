//
//  MobiAdTact.m
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MobiAdTact.h"


NSString *const kMobiTactFreqCount = @"freq_count";
NSString *const kMobiTactFreqTime = @"freq_time";
NSString *const kMobiTactPcache = @"pcache";


@interface MobiAdTact ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MobiAdTact

@synthesize freqCount = _freqCount;
@synthesize freqTime = _freqTime;
@synthesize pcache = _pcache;


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
            self.freqCount = [[self objectOrNilForKey:kMobiTactFreqCount fromDictionary:dict] doubleValue];
            self.freqTime = [[self objectOrNilForKey:kMobiTactFreqTime fromDictionary:dict] doubleValue];
            self.pcache = [[self objectOrNilForKey:kMobiTactPcache fromDictionary:dict] doubleValue];

    }
    
    return self;
    
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


@end
