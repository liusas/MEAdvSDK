//
//  MobiAdConfigServer.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/6.
//

#import <Foundation/Foundation.h>
#import "MobiConfig.h"
#import "MobiGlobal.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MobiAdConfigServerDelegate;

/// 广告配置信息请求服务
@interface MobiAdConfigServer : NSObject

@property (nonatomic, weak) id<MobiAdConfigServerDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL loading;

- (id)initWithDelegate:(id<MobiAdConfigServerDelegate>)delegate;

- (void)loadURL:(NSURL *)URL;
- (void)cancel;

@end

@protocol MobiAdConfigServerDelegate <NSObject>

@required
- (void)communicatorDidReceiveAdConfigurations:(NSArray<MobiConfig *> *)configurations;
- (void)communicatorDidFailWithError:(NSError *)error;

- (BOOL)isFullscreenAd;
- (NSString *)adUnitId;
@end

NS_ASSUME_NONNULL_END
