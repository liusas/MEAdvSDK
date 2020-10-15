//
//  MobiAdTargeting.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobiAdTargeting : NSObject

/// 广告容器允许的最大安全尺寸,即屏幕分辨率
@property (nonatomic, assign) CGSize creativeSafeSize;

/// 非个人可鉴别的关键字字符串,传递给服务器来获取更精准的广告
@property (nullable, nonatomic, copy) NSString * keywords;

/**
 适用于custom event的键值对,mopub本意是,custom event可以由SDK外部去实现,这个字段用于传递一些custom evnet需要,而SDK中无法传递的字段,以localExtras传递,暂时保留这个字段,以便日后进行精细化拆分
 */
@property (nullable, nonatomic, copy) NSDictionary * localExtras;

/**
 这是一组用逗号分隔的键值对,例如{"marital:single, age:24"}
 用于针对用户群推送更加精准的广告,
 若App没有获得用户同意,则这些数据将不会被发送到服务器
 */
@property (nullable, nonatomic, copy) NSString * userDataKeywords;

/**
信息流广告尺寸，必须传入宽度，高度自适应，否则无法展示信息流
*/
@property (nonatomic, assign) CGSize feedSize;

/**
 初始化AdTargeting
 @param size 广告容器允许的最大安全尺寸
 */
- (instancetype)initWithCreativeSafeSize:(CGSize)size;

/**
 初始化AdTargeting
 @param size 广告容器允许的最大安全尺寸
*/
+ (instancetype)targetingWithCreativeSafeSize:(CGSize)size;

#pragma mark - Unavailable Initializers

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
