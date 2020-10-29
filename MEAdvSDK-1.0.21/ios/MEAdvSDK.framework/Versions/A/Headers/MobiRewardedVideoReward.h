//
//  MobiRewardedVideoReward.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * A constant that indicates that no currency type was specified with the reward.
 */
extern NSString *const kMobiRewardedVideoRewardCurrencyTypeUnspecified;

/**
 * A constant that indicates that no currency amount was specified with the reward.
 */
extern NSInteger const kMobiRewardedVideoRewardCurrencyAmountUnspecified;


/**
 * `MobiRewardedVideoReward` contains all the information needed to reward the user for watching
 * a rewarded video ad. The class provides a currency amount and currency type.
 */

@interface MobiRewardedVideoReward : NSObject

/**
 * The type of currency that should be rewarded to the user.
 *
 * An undefined currency type should be specified as `kMobiRewardedVideoRewardCurrencyTypeUnspecified`.
 */
@property (nonatomic, readonly) NSString *currencyType;

/**
 * The amount of currency to reward to the user.
 *
 * An undefined currency amount should be specified as `kMobiRewardedVideoRewardCurrencyAmountUnspecified`
 * wrapped as an NSNumber.
 */
@property (nonatomic, readonly) NSNumber *amount;

/**
 * Initializes the object with an undefined currency type (`kMobiRewardedVideoRewardCurrencyTypeUnspecified`) and
 * the amount passed in.
 *
 * @param amount The amount of currency the user is receiving.
 */
- (instancetype)initWithCurrencyAmount:(NSNumber *)amount;

/**
 * Initializes the object's properties with the currencyType and amount.
 *
 * @param currencyType The type of currency the user is receiving.
 * @param amount The amount of currency the user is receiving.
 */
- (instancetype)initWithCurrencyType:(NSString *)currencyType amount:(NSNumber *)amount;

@end

NS_ASSUME_NONNULL_END
