//
//  MobiAdVideoVideoAdm.h
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MobiAdVideoVideoAdm : NSObject

@property (nonatomic, strong) NSArray *startPlay;
@property (nonatomic, strong) NSArray *finishPlay;
@property (nonatomic, strong) NSArray *skipPlay;
@property (nonatomic, strong) NSString *button;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *midPlay;
@property (nonatomic, strong) NSString *logo;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSArray *imgTrack;
@property (nonatomic, strong) NSArray *firstQuarterPlay;
@property (nonatomic, strong) NSArray *thirdQuarterPlay;
@property (nonatomic, strong) NSArray *clkTrack;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
