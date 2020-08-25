//
//  MobiFeedModel.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import <Foundation/Foundation.h>

@interface MobiFeedModel : NSObject

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
 *  用于针对用户群推送更加精准的广告,
 *  若App没有获得用户同意,则这些数据将不会被发送到服务器
 */
@property (nullable, nonatomic, copy) NSString * userDataKeywords;

/**
 *  一次加载信息流广告的个数
 */
@property (nonatomic, assign) NSInteger count;

/**
 *  非 WiFi 网络，是否自动播放。默认 NO。loadAd 前设置。
 */
@property (nonatomic, assign) BOOL videoAutoPlayOnWWAN;

/**
 *  自动播放时，是否静音。默认 YES。loadAd 前设置。
 */
@property (nonatomic, assign) BOOL videoMuted;

/**
 请求视频的时长上限，有效值范围为[5,60]。
 */
@property (nonatomic) NSInteger maxVideoDuration;

/**
 信息流广告尺寸，必须传入宽度，高度自适应，否则无法展示信息流
 */
@property (nonatomic, assign) CGSize feedSize;

@end


