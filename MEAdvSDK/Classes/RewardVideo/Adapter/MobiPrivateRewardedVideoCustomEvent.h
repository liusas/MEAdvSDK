//
//  MobiPrivateRewardedVideoCustomEvent.h
//  MobiPubSDK
//
//  Created by 李新丰 on 2020/8/6.
//

#import "MobiRewardedVideoCustomEvent.h"
#import "MobiPrivateRewardedVideoCustomEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobiPrivateRewardedVideoCustomEvent : MobiRewardedVideoCustomEvent

@property (nonatomic, weak) id<MobiPrivateRewardedVideoCustomEventDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
