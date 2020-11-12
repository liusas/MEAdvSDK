//
//  MobiGlobalConfigServer.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/23.
//

#import <Foundation/Foundation.h>
#import "MobiPubConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

/// 初始化完成的block
typedef void(^ConfigManangerFinished)(NSDictionary *serverConfig);

@interface MobiGlobalConfigServer : NSObject

/// 是否正在请求
@property (nonatomic, assign, readonly) BOOL loading;

- (void)cancel;

/// 从服务端请求平台配置信息
- (void)loadWithConfiguration:(MobiPubConfiguration *)configuration
                     finished:(ConfigManangerFinished)finished;

@end

NS_ASSUME_NONNULL_END
