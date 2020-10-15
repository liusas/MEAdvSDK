//
//  MobiAdNativeDlink.m
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MobiAdNativeDlink.h"


NSString *const kMobiAdNativeDlinkDurl = @"durl";
NSString *const kMobiAdNativeDlinkWurl = @"wurl";


@interface MobiAdNativeDlink ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MobiAdNativeDlink

@synthesize durl = _durl;
@synthesize wurl = _wurl;


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
            self.durl = [self objectOrNilForKey:kMobiAdNativeDlinkDurl fromDictionary:dict];
            self.wurl = [self objectOrNilForKey:kMobiAdNativeDlinkWurl fromDictionary:dict];

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
