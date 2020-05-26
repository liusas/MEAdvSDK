//
//  MEAdHelpTool.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEAdHelpTool : NSObject

// 获取时间戳,以天为单位
+ (NSString *)getDayStr;
// 获取时间戳,以分为单位
+ (NSString *)getTimeStr;

@end

NS_ASSUME_NONNULL_END
