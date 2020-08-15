//
//  MobiPub.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/28.
//

#import <Foundation/Foundation.h>
#import "MobiPubConfiguration.h"
#import "MobiRewardedVideo.h"
#import "MobiFeed.h"
#import "MobiInterstitial.h"
#import "MPInterstitialAdController.h"
#import "MobiSplash.h"
#import "MPAdView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobiPub : NSObject

/**
 * Returns the MobiPub singleton object.
 *
 * @return The MobiPub singleton object.
 */
+ (MobiPub * _Nonnull)sharedInstance;

/**
 * A Boolean value indicating whether the MobiPub SDK should use Core Location APIs to automatically
 * derive targeting information for location-based ads.
 *
 * When set to NO, the SDK will not attempt to determine device location. When set to YES, the
 * SDK will periodically try to listen for location updates in order to request location-based ads.
 * This only occurs if location services are enabled and the user has already authorized the use
 * of location services for the application. The default value is YES.
 *
 * If a user is in General Data Protection Regulation (GDPR) region and
 * MobiPub doesn't obtain consent from the user for using his/her personal data,
 * locationUpdatesEnabled will always be set to NO.
 *
 * @return A Boolean value indicating whether the SDK should listen for location updates.
 */
@property (nonatomic, assign) BOOL locationUpdatesEnabled;

/**
 * A Boolean value indicating whether the MobiPub SDK should create a MobiPub ID that can be used
 * for frequency capping when Limit ad tracking is on & the IDFA we get is
 * 00000000-0000-0000-0000-000000000000.
 *
 * When set to NO, the SDK will not create a MobiPub ID in the above case. When set to YES, the
 * SDK will generate a MobiPub ID. The default value is YES.
 *
 */
@property (nonatomic) BOOL frequencyCappingIdUsageEnabled;

/**
 * Initializes the MoPub SDK asynchronously on a background thread.
 * @remark This should be called from the app's `application:didFinishLaunchingWithOptions:` method.
 * @param configuration Required SDK configuration options.
 * @param completionBlock Optional completion block that will be called when initialization has completed.
 */
- (void)initializeSdkWithConfiguration:(MobiPubConfiguration * _Nonnull)configuration
                            completion:(void(^_Nullable)(void))completionBlock;

/**
 * A boolean value indicating if the SDK has been initialized. This property's value is @c YES if
 * @c initializeSdkWithConfiguration:completion: has been called and completed; the value is @c NO otherwise.
 */
@property (nonatomic, readonly) BOOL isSdkInitialized;

- (NSString * _Nonnull)version;
- (NSString * _Nonnull)bundleIdentifier;

@end

NS_ASSUME_NONNULL_END
