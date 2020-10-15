//
//  MobiAdVideoVideoAdm.m
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MobiAdVideoVideoAdm.h"


NSString *const kMobiAdVideoVideoAdmStartPlay = @"start_play";
NSString *const kMobiAdVideoVideoAdmFinishPlay = @"finish_play";
NSString *const kMobiAdVideoVideoAdmSkipPlay = @"skip_play";
NSString *const kMobiAdVideoVideoAdmButton = @"button";
NSString *const kMobiAdVideoVideoAdmTitle = @"title";
NSString *const kMobiAdVideoVideoAdmMidPlay = @"mid_play";
NSString *const kMobiAdVideoVideoAdmLogo = @"logo";
NSString *const kMobiAdVideoVideoAdmVideoUrl = @"video_url";
NSString *const kMobiAdVideoVideoAdmDesc = @"desc";
NSString *const kMobiAdVideoVideoAdmImgTrack = @"img_track";
NSString *const kMobiAdVideoVideoAdmFirstQuarterPlay = @"first_quarter_play";
NSString *const kMobiAdVideoVideoAdmThirdQuarterPlay = @"third_quarter_play";
NSString *const kMobiAdVideoVideoAdmClkTrack = @"clk_track";


@interface MobiAdVideoVideoAdm ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MobiAdVideoVideoAdm

@synthesize startPlay = _startPlay;
@synthesize finishPlay = _finishPlay;
@synthesize skipPlay = _skipPlay;
@synthesize button = _button;
@synthesize title = _title;
@synthesize midPlay = _midPlay;
@synthesize logo = _logo;
@synthesize videoUrl = _videoUrl;
@synthesize desc = _desc;
@synthesize imgTrack = _imgTrack;
@synthesize firstQuarterPlay = _firstQuarterPlay;
@synthesize thirdQuarterPlay = _thirdQuarterPlay;
@synthesize clkTrack = _clkTrack;


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
            self.startPlay = [self objectOrNilForKey:kMobiAdVideoVideoAdmStartPlay fromDictionary:dict];
            self.finishPlay = [self objectOrNilForKey:kMobiAdVideoVideoAdmFinishPlay fromDictionary:dict];
            self.skipPlay = [self objectOrNilForKey:kMobiAdVideoVideoAdmSkipPlay fromDictionary:dict];
            self.button = [self objectOrNilForKey:kMobiAdVideoVideoAdmButton fromDictionary:dict];
            self.title = [self objectOrNilForKey:kMobiAdVideoVideoAdmTitle fromDictionary:dict];
            self.midPlay = [self objectOrNilForKey:kMobiAdVideoVideoAdmMidPlay fromDictionary:dict];
            self.logo = [self objectOrNilForKey:kMobiAdVideoVideoAdmLogo fromDictionary:dict];
            self.videoUrl = [self objectOrNilForKey:kMobiAdVideoVideoAdmVideoUrl fromDictionary:dict];
            self.desc = [self objectOrNilForKey:kMobiAdVideoVideoAdmDesc fromDictionary:dict];
            self.imgTrack = [self objectOrNilForKey:kMobiAdVideoVideoAdmImgTrack fromDictionary:dict];
            self.firstQuarterPlay = [self objectOrNilForKey:kMobiAdVideoVideoAdmFirstQuarterPlay fromDictionary:dict];
            self.thirdQuarterPlay = [self objectOrNilForKey:kMobiAdVideoVideoAdmThirdQuarterPlay fromDictionary:dict];
            self.clkTrack = [self objectOrNilForKey:kMobiAdVideoVideoAdmClkTrack fromDictionary:dict];

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
