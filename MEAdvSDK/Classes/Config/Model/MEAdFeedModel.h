//
//  MEAdFeedModel.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/12/13.
//  拉取信息流广告需要传递的参数

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEAdFeedModel : NSObject

/// 广告场景id
@property (nonatomic, copy) NSString *sceneId;
/// 容纳信息流广告容器宽度
@property (nonatomic, assign) CGFloat width;

@end

NS_ASSUME_NONNULL_END
