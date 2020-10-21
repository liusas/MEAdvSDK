//
//  MobiRewardedVideoModel.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobiRewardedVideoModel : NSObject

/// 用来标识唯一用户,方便更精准的广告投放
@property (nonatomic, copy) NSString *userId;

/// 非个人可鉴别的关键字字符串,传递给服务器来获取更精准的广告
@property (nullable, nonatomic, copy) NSString * keywords;

/**
 *  适用于custom event的键值对,mopub本意是,custom event可以由SDK外部去实现,这个字段用于传递一些custom evnet需要,而SDK中无法传递的字段,以localExtras传递,暂时保留这个字段,以便日后进行精细化拆分
 */
@property (nullable, nonatomic, copy) NSDictionary * localExtras;

/**
 *  这是一组用逗号分隔的键值对,例如{"marital:single, age:24"}
 *  用于针对用户群推送更加精准的广告,
 *  若App没有获得用户同意,则这些数据将不会被发送到服务器
 */
@property (nullable, nonatomic, copy) NSString * userDataKeywords;

@end

NS_ASSUME_NONNULL_END
