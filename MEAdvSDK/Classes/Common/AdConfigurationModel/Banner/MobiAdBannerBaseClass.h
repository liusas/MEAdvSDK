//
//  MobiAdBannerBaseClass.h
//
//  Created by 峰 刘 on 2020/7/30
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobiAdTact.h"

@interface MobiAdBannerBaseClass : NSObject

@property (nonatomic, assign) double fw;
@property (nonatomic, assign) double style;
@property (nonatomic, assign) double bdt;
@property (nonatomic, strong) NSArray *clkTrack;
@property (nonatomic, assign) double height;
@property (nonatomic, assign) double width;
@property (nonatomic, strong) NSString *ad;
@property (nonatomic, strong) NSString *adid;
@property (nonatomic, strong) NSArray *imgTrack;
@property (nonatomic, assign) double ctype;
@property (nonatomic, strong) MobiAdTact *tact;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
