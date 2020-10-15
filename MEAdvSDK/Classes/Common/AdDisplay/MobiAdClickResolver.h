//
//  MobiAdClickResolver.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/13.
//

#import <Foundation/Foundation.h>
#import "MobiGlobal.h"
#import "MPURLActionInfo.h"

typedef void (^MobiAdClickResolverCompletionBlock)(MPURLActionInfo *actionInfo, NSError *error);

@interface MobiAdClickResolver : NSObject

+ (instancetype)resolverWithDict:(NSDictionary *)resolveDic completion:(MobiAdClickResolverCompletionBlock)completion;
- (void)start;
- (void)cancel;

@end
