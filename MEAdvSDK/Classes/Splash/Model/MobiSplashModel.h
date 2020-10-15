//
//  MobiSplashModel.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobiSplashModel : NSObject

/**
 *  拉取广告超时时间，默认为3秒
 *  详解：拉取广告超时时间，开发者调用loadAd方法以后会立即展示backgroundImage，然后在该超时时间内，如果广告拉
 *  取成功，则立马展示开屏广告，否则放弃此次广告展示机会。
 */
@property (nonatomic, assign) NSInteger fetchDelay;

/**
 *  开屏广告的背景图片
 *  可以设置背景图片作为开屏加载时的默认背景
 */
@property (nonatomic, strong) UIImage *backgroundImage;

/**
 *  开屏广告的背景色
 *  可以设置开屏图片来作为开屏加载时的默认图片
 */
@property (nonatomic, copy) UIColor *backgroundColor;

/**
 *  跳过按钮的位置
 */
@property (nonatomic, assign) CGPoint skipButtonCenter;

/**
 *  用来标识唯一用户,方便更精准的广告投放
 */
@property (nonatomic, copy) NSString *userId;

/**
 *  非个人可鉴别的关键字字符串,传递给服务器来获取更精准的广告
 */
@property (nullable, nonatomic, copy) NSString * keywords;

/**
 *  适用于custom event的键值对,mopub本意是,custom event可以由SDK外部去实现,这个字段用于传递一些custom evnet需要,而SDK中无法传递的字段,以localExtras传递,暂时保留这个字段,以便日后进行精细化拆分
 */
@property (nullable, nonatomic, copy) NSDictionary * localExtras;

/**
 *  这是一组用逗号分隔的键值对,例如{"marital:single, age:24"}
 *  用于针对用户群推送更加精准的广告
 *  若App没有获得用户同意,则这些数据将不会被发送到服务器
 */
@property (nullable, nonatomic, copy) NSString * userDataKeywords;

@end

NS_ASSUME_NONNULL_END
