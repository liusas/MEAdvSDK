//
//  MELogTracker.h
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/10/14.
//

#import <Foundation/Foundation.h>
#import "MEAdLogModel.h"
#import "MEAdHelpTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface MELogTracker : NSObject

+ (void)uploadImmediatelyWithLogModels:(NSArray <MEAdLogModel *>*)logs;

@end

NS_ASSUME_NONNULL_END
