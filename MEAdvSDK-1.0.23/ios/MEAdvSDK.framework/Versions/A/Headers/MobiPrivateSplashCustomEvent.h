//
//  MobiPrivateSplashCustomEvent.h
//  MobiPubSDK
//
//  Created by 卢镝 on 2020/7/9.
//

#import "MobiSplashCustomEvent.h"
#import "MobiPrivateSplashCustomEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobiPrivateSplashCustomEvent : MobiSplashCustomEvent

@property (nonatomic, weak) id<MobiPrivateSplashCustomEventDelegate> delegate;

@property(nonatomic,assign,readonly) CGPoint clickDownPoint;

@property(nonatomic,assign,readonly) CGPoint clickUpPoint;

@end

NS_ASSUME_NONNULL_END
