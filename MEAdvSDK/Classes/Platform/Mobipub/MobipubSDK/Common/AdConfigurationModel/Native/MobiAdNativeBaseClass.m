//
//  MobiAdNativeBaseClass.m
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import "MobiAdNativeBaseClass.h"

NSString *const kMobiAdNativeBaseClassStyle = @"style";
NSString *const kMobiAdNativeBaseClassCurl = @"curl";
NSString *const kMobiAdNativeBaseClassCtype = @"ctype";
NSString *const kMobiAdNativeBaseClassPkg = @"pkg";
NSString *const kMobiAdNativeBaseClassTact = @"tact";
NSString *const kMobiAdNativeBaseClassFinishDownload = @"finish_download";
NSString *const kMobiAdNativeBaseClassImpTrack = @"imp_track";
NSString *const kMobiAdNativeBaseClassDesc = @"desc";
NSString *const kMobiAdNativeBaseClassTitle = @"title";
NSString *const kMobiAdNativeBaseClassLogo = @"logo";
NSString *const kMobiAdNativeBaseClassImg = @"img";
NSString *const kMobiAdNativeBaseClassStartDownload = @"start_download";
NSString *const kMobiAdNativeBaseClassStyleType = @"style_type";
NSString *const kMobiAdNativeBaseClassDlinkTrack = @"dlink_track";
NSString *const kMobiAdNativeBaseClassDlinkDurl = @"dlink_durl";
NSString *const kMobiAdNativeBaseClassDlinkWurl = @"dlink_wurl";
NSString *const kMobiAdNativeBaseClassAdid = @"adid";
NSString *const kMobiAdNativeBaseClassClkTrack = @"clk_track";

NSString *const kMobiAdNativeBaseClassStartInstall = @"start_install";
NSString *const kMobiAdNativeBaseClassFinishInstall = @"finish_install";
NSString *const kMobiAdNativeBaseClassActiveApp = @"active_app";

@interface MobiAdNativeBaseClass ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation MobiAdNativeBaseClass

@synthesize style = _style;
@synthesize curl = _curl;
@synthesize ctype = _ctype;
@synthesize pkg = _pkg;
@synthesize tact = _tact;
@synthesize finishDownload = _finishDownload;
@synthesize impTrack = _impTrack;
@synthesize desc = _desc;
@synthesize title = _title;
@synthesize logo = _logo;
@synthesize img = _img;
@synthesize startDownload = _startDownload;
@synthesize styleType = _styleType;
@synthesize dlinkTrack = _dlinkTrack;
@synthesize dlinkDurl = _dlinkDurl;
@synthesize dlinkWurl = _dlinkWurl;
@synthesize adid = _adid;
@synthesize clkTrack = _clkTrack;
@synthesize startInstall = _startInstall;
@synthesize finishInstall = _finishInstall;
@synthesize activeApp = _activeApp;


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
        self.style = [[self objectOrNilForKey:kMobiAdNativeBaseClassStyle fromDictionary:dict] doubleValue];
        self.curl = [self objectOrNilForKey:kMobiAdNativeBaseClassCurl fromDictionary:dict];
        self.ctype = [[self objectOrNilForKey:kMobiAdNativeBaseClassCtype fromDictionary:dict] doubleValue];
        self.pkg = [self objectOrNilForKey:kMobiAdNativeBaseClassPkg fromDictionary:dict];
        self.tact = [MobiAdTact modelObjectWithDictionary:[dict objectForKey:kMobiAdNativeBaseClassTact]];
        self.finishDownload = [self objectOrNilForKey:kMobiAdNativeBaseClassFinishDownload fromDictionary:dict];
        self.startInstall = [self objectOrNilForKey:kMobiAdNativeBaseClassStartInstall fromDictionary:dict];
        self.finishInstall = [self objectOrNilForKey:kMobiAdNativeBaseClassFinishInstall fromDictionary:dict];
        self.activeApp = [self objectOrNilForKey:kMobiAdNativeBaseClassActiveApp fromDictionary:dict];
        self.impTrack = [self objectOrNilForKey:kMobiAdNativeBaseClassImpTrack fromDictionary:dict];
        self.desc = [self objectOrNilForKey:kMobiAdNativeBaseClassDesc fromDictionary:dict];
        self.title = [self objectOrNilForKey:kMobiAdNativeBaseClassTitle fromDictionary:dict];
        self.logo = [self objectOrNilForKey:kMobiAdNativeBaseClassLogo fromDictionary:dict];
        NSObject *receivedMobiAdNativeImg = [dict objectForKey:kMobiAdNativeBaseClassImg];
        NSMutableArray *parsedMobiAdNativeImg = [NSMutableArray array];
        if ([receivedMobiAdNativeImg isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in (NSArray *)receivedMobiAdNativeImg) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [parsedMobiAdNativeImg addObject:[MobiAdNativeImg modelObjectWithDictionary:item]];
                }
            }
        } else if ([receivedMobiAdNativeImg isKindOfClass:[NSDictionary class]]) {
            [parsedMobiAdNativeImg addObject:[MobiAdNativeImg modelObjectWithDictionary:(NSDictionary *)receivedMobiAdNativeImg]];
        }
        
        self.img = [NSArray arrayWithArray:parsedMobiAdNativeImg];
        self.startDownload = [self objectOrNilForKey:kMobiAdNativeBaseClassStartDownload fromDictionary:dict];
        self.styleType = [[self objectOrNilForKey:kMobiAdNativeBaseClassStyleType fromDictionary:dict] doubleValue];
        self.dlinkTrack = [self objectOrNilForKey:kMobiAdNativeBaseClassDlinkTrack fromDictionary:dict];
        self.dlinkDurl = [self objectOrNilForKey:kMobiAdNativeBaseClassDlinkDurl fromDictionary:dict];
        self.dlinkWurl = [self objectOrNilForKey:kMobiAdNativeBaseClassDlinkWurl fromDictionary:dict];
        self.adid = [self objectOrNilForKey:kMobiAdNativeBaseClassAdid fromDictionary:dict];
        self.clkTrack = [self objectOrNilForKey:kMobiAdNativeBaseClassClkTrack fromDictionary:dict];
        
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
