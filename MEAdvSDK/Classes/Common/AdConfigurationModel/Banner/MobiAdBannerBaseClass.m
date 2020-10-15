//
//  MobiAdBannerBaseClass.m
//
//  Created by 峰 刘 on 2020/7/30
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MobiAdBannerBaseClass.h"

NSString *const kMobiAdBannerBaseClassFw = @"fw";
NSString *const kMobiAdBannerBaseClassStyle = @"style";
NSString *const kMobiAdBannerBaseClassBdt = @"bdt";
NSString *const kMobiAdBannerBaseClassClkTrack = @"clk_track";
NSString *const kMobiAdBannerBaseClassHeight = @"height";
NSString *const kMobiAdBannerBaseClassWidth = @"width";
NSString *const kMobiAdBannerBaseClassAd = @"ad";
NSString *const kMobiAdBannerBaseClassAdid = @"adid";
NSString *const kMobiAdBannerBaseClassImgTrack = @"img_track";
NSString *const kMobiAdBannerBaseClassCtype = @"ctype";
NSString *const kMobiAdBannerBaseClassTact = @"tact";


@interface MobiAdBannerBaseClass ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MobiAdBannerBaseClass

@synthesize fw = _fw;
@synthesize style = _style;
@synthesize bdt = _bdt;
@synthesize clkTrack = _clkTrack;
@synthesize height = _height;
@synthesize width = _width;
@synthesize ad = _ad;
@synthesize adid = _adid;
@synthesize imgTrack = _imgTrack;
@synthesize ctype = _ctype;
@synthesize tact = _tact;


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
            self.fw = [[self objectOrNilForKey:kMobiAdBannerBaseClassFw fromDictionary:dict] doubleValue];
            self.style = [[self objectOrNilForKey:kMobiAdBannerBaseClassStyle fromDictionary:dict] doubleValue];
            self.bdt = [[self objectOrNilForKey:kMobiAdBannerBaseClassBdt fromDictionary:dict] doubleValue];
            self.clkTrack = [self objectOrNilForKey:kMobiAdBannerBaseClassClkTrack fromDictionary:dict];
            self.height = [[self objectOrNilForKey:kMobiAdBannerBaseClassHeight fromDictionary:dict] doubleValue];
            self.width = [[self objectOrNilForKey:kMobiAdBannerBaseClassWidth fromDictionary:dict] doubleValue];
            self.ad = [self objectOrNilForKey:kMobiAdBannerBaseClassAd fromDictionary:dict];
            self.adid = [self objectOrNilForKey:kMobiAdBannerBaseClassAdid fromDictionary:dict];
            self.imgTrack = [self objectOrNilForKey:kMobiAdBannerBaseClassImgTrack fromDictionary:dict];
            self.ctype = [[self objectOrNilForKey:kMobiAdBannerBaseClassCtype fromDictionary:dict] doubleValue];
            self.tact = [MobiAdTact modelObjectWithDictionary:[dict objectForKey:kMobiAdBannerBaseClassTact]];

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
