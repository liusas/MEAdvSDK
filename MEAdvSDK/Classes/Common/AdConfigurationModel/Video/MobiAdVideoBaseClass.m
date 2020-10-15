//
//  MobiAdVideoBaseClass.m
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MobiAdVideoBaseClass.h"
#import "MobiAdVideoVideoAdm.h"


NSString *const kMobiAdVideoBaseClassVideoAdm = @"video_adm";
NSString *const kMobiAdVideoBaseClassStyle = @"style";
NSString *const kMobiAdVideoBaseClassActiveApp = @"active_app";
NSString *const kMobiAdVideoBaseClassStartDownload = @"start_download";
NSString *const kMobiAdVideoBaseClassFinishDownload = @"finish_download";
NSString *const kMobiAdVideoBaseClassFinishInstall = @"finish_install";
NSString *const kMobiAdVideoBaseClassAdid = @"adid";
NSString *const kMobiAdVideoBaseClassStyleType = @"style_type";
NSString *const kMobiAdVideoBaseClassCtype = @"ctype";
NSString *const kMobiAdVideoBaseClassStartInstall = @"start_install";
NSString *const kMobiAdVideoBaseClassTact = @"tact";

NSString *const kMobiAdVideoBaseClassClkTrack = @"clk_track";
NSString *const kMobiAdVideoBaseClassImgtrack = @"img_track";
NSString *const kMobiAdVideoBaseClassCurl = @"curl";
NSString *const kMobiAdVideoBaseClassDlinkTrack = @"dlink_track";
NSString *const kMobiAdVideoBaseClassDlinkDurl = @"dlink_durl";
NSString *const kMobiAdVideoBaseClassDlinkWurl = @"dlink_wurl";


@interface MobiAdVideoBaseClass ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MobiAdVideoBaseClass

@synthesize videoAdm = _videoAdm;
@synthesize style = _style;
@synthesize activeApp = _activeApp;
@synthesize startDownload = _startDownload;
@synthesize finishDownload = _finishDownload;
@synthesize finishInstall = _finishInstall;
@synthesize adid = _adid;
@synthesize styleType = _styleType;
@synthesize ctype = _ctype;
@synthesize startInstall = _startInstall;
@synthesize tact = _tact;
@synthesize dlink_durl = _dlink_durl;
@synthesize dlink_wurl = _dlink_wurl;
@synthesize dlink_track = _dlink_track;
@synthesize img_track = _img_track;
@synthesize clk_track = _clk_track;
@synthesize curl = _curl;


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
        self.videoAdm = [MobiAdVideoVideoAdm modelObjectWithDictionary:[dict objectForKey:kMobiAdVideoBaseClassVideoAdm]];
        self.style = [[self objectOrNilForKey:kMobiAdVideoBaseClassStyle fromDictionary:dict] doubleValue];
        self.tact = [MobiAdTact modelObjectWithDictionary:[dict objectForKey:kMobiAdVideoBaseClassTact]];
        self.activeApp = [self objectOrNilForKey:kMobiAdVideoBaseClassActiveApp fromDictionary:dict];
        self.startDownload = [self objectOrNilForKey:kMobiAdVideoBaseClassStartDownload fromDictionary:dict];
        self.finishDownload = [self objectOrNilForKey:kMobiAdVideoBaseClassFinishDownload fromDictionary:dict];
        self.finishInstall = [self objectOrNilForKey:kMobiAdVideoBaseClassFinishInstall fromDictionary:dict];
        self.adid = [self objectOrNilForKey:kMobiAdVideoBaseClassAdid fromDictionary:dict];
        self.styleType = [[self objectOrNilForKey:kMobiAdVideoBaseClassStyleType fromDictionary:dict] doubleValue];
        self.ctype = [[self objectOrNilForKey:kMobiAdVideoBaseClassCtype fromDictionary:dict] doubleValue];
        self.startInstall = [self objectOrNilForKey:kMobiAdVideoBaseClassStartInstall fromDictionary:dict];
        self.curl = [self objectOrNilForKey:kMobiAdVideoBaseClassCurl fromDictionary:dict];
        self.img_track = [self objectOrNilForKey:kMobiAdVideoBaseClassImgtrack fromDictionary:dict];
        self.dlink_track = [self objectOrNilForKey:kMobiAdVideoBaseClassDlinkTrack fromDictionary:dict];
        self.dlink_durl = [self objectOrNilForKey:kMobiAdVideoBaseClassDlinkDurl fromDictionary:dict];
        self.dlink_wurl = [self objectOrNilForKey:kMobiAdVideoBaseClassDlinkWurl fromDictionary:dict];
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
