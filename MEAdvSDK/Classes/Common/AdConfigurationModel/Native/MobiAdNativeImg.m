//
//  MobiAdNativeImg.m
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MobiAdNativeImg.h"


NSString *const kMobiAdNativeImgUrl = @"url";
NSString *const kMobiAdNativeImgW = @"w";
NSString *const kMobiAdNativeImgH = @"h";


@interface MobiAdNativeImg ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MobiAdNativeImg

@synthesize url = _url;
@synthesize w = _w;
@synthesize h = _h;


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
            self.url = [self objectOrNilForKey:kMobiAdNativeImgUrl fromDictionary:dict];
            self.w = [self objectOrNilForKey:kMobiAdNativeImgW fromDictionary:dict];
            self.h = [self objectOrNilForKey:kMobiAdNativeImgH fromDictionary:dict];

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
