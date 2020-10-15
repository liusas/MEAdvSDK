//
//  MobiAdTact.h
//
//  Created by 峰 刘 on 2020/7/7
//  Copyright (c) 2020 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobiAdTact : NSObject <NSCoding, NSCopying>
/// 广告缓存时间，单位秒
@property (nonatomic, assign) double pcache;
/// 展现频次控制时间，单位秒
@property (nonatomic, assign) double freqTime;
/// 在freq_time时间内的展现频次
@property (nonatomic, assign) double freqCount;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
