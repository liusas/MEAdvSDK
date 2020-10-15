//
//  MobiExperimentProvider.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/28.
//

#import <Foundation/Foundation.h>
#import "MobiPubDisplayAgentType.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobiExperimentProvider : NSObject

@property (nonatomic, assign) MobiPubDisplayAgentType displayAgentType;

+ (instancetype)sharedInstance;

- (void)setDisplayAgentFromAdServer:(MobiPubDisplayAgentType)displayAgentType;

@end

NS_ASSUME_NONNULL_END
