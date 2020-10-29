//
//  MobiGlobalConfig.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/23.
//

#import <Foundation/Foundation.h>
#import "MEAdvConfig.h"
#import "MEConfigBaseClass.h"

NS_ASSUME_NONNULL_BEGIN
@interface MobiGlobalConfig : NSObject

/// 聚合平台appid,平台会为用户分配appid
/// 可在调用requestPlatformConfigWithUrl时传入,或直接赋值,但要早于调用requestPlatformConfigWithUrl
@property (nonatomic, copy) NSString *platformAppid;
/// 请求 填充 展现 点击的日志上报URL
@property (nonatomic, copy) NSString *adLogUrl;
/// 其他事件上报URL
@property (nonatomic, copy) NSString *developerUrl;
/// 广告请求的超时时长
@property (nonatomic, assign) NSTimeInterval adRequestTimeout;

/// 设备id
@property (nonatomic, copy) NSString *deviceId;

/// 广告平台配置信息字典,已删减排序
@property (nonatomic, strong) NSMutableDictionary *configDic;

/// 判断广告平台是否已经初始化
@property (nonatomic, assign) BOOL isInit;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
