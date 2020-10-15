//
//  MobiConfig.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/6.
//

#import "MobiConfig.h"
#import "NSString+MPAdditions.h"

static NSTimeInterval const kDefaultRefreshInterval = 10; //seconds

@interface MobiConfig ()

@property (nonatomic, copy) NSString *adResponseHTMLString;

@end

@implementation MobiConfig

/// 请求下来的广告配置字典,转化成数据模型
- (instancetype)initWithAdConfigResponse:(NSDictionary *)json {
    self = [super init];
    if (self) {
        [self commonInitWithJson:json];
    }
    return self;
}

/// 初始化
- (void)commonInitWithJson:(NSDictionary *)json {
    self.adType = [self adTypeFromStypeType:[json[@"style_type"] integerValue]];
    [self configWithAdType:self.adType];
    
    self.refreshInterval = kDefaultRefreshInterval;
    
    if (self.adType == MobiAdTypeBanner || self.adType == MobiAdTypeFeed || self.adType == MobiAdTypeInterstitial || self.adType == MobiAdTypeSplash) {
        
        self.nativeConfigData = [MobiAdNativeBaseClass modelObjectWithDictionary:json];
        self.impressionTrackingURLs = [self URLsFromArray:self.nativeConfigData.impTrack];
        self.clickTrackingURLs = [self URLsFromArray:self.nativeConfigData.clkTrack];
        
    } else if (self.adType == MobiAdTypeFullScreenVideo || self.adType == MobiAdTypeRewardedVideo) {
        
        self.videoConfigData = [MobiAdVideoBaseClass modelObjectWithDictionary:json];
        self.impressionTrackingURLs = [self URLsFromArray:self.videoConfigData.videoAdm.imgTrack];
        self.clickTrackingURLs = [self URLsFromArray:self.nativeConfigData.clkTrack];
    }
    
    /// 广告请求时长限制10秒
    self.adTimeoutInterval = 10;
    
}

/// 返回广告位乐行
/// @param styleType 一级广告样式
- (MobiAdType)adTypeFromStypeType:(NSInteger)styleType {
    if (styleType == 101) { // 横幅广告
        return MobiAdTypeBanner;
    } else if (styleType == 102) { // 信息流
        return MobiAdTypeFeed;
    } else if (styleType == 103) { // 激励视频
        return MobiAdTypeRewardedVideo;
    } else if (styleType == 104) { // 全屏视频
        return MobiAdTypeFullScreenVideo;
    } else if (styleType == 105) { // 插屏
        return MobiAdTypeInterstitial;
    } else if (styleType == 106) { // 开屏
        return MobiAdTypeSplash;
    }
    
    // 若至此,则表示广告类型错误
    return MobiAdTypeUnknown;
}

/// 配置MobiConfig的成员变量
- (void)configWithAdType:(MobiAdType)adType {
    // 装配数据模型,分配具体广告执行类
    switch (adType) {
        case MobiAdTypeBanner: {
            /// 横幅广告
            self.customEventClass = NSClassFromString(@"MobiPrivateBannerCustomEvent");
        }
            break;
        case MobiAdTypeFeed: {
            /// 信息流广告
            self.customEventClass = NSClassFromString(@"MobiPrivateFeedCustomEvent");
        }
            break;
        case MobiAdTypeInterstitial: {
            /// 插屏广告
            self.customEventClass = NSClassFromString(@"MobiPrivateInterstitialCustomEvent");
        }
            break;
        case MobiAdTypeSplash: {
            /// 开屏广告
            self.customEventClass = NSClassFromString(@"MobiPrivateSplashCustomEvent");
        }
            break;
        case MobiAdTypeRewardedVideo: {
            /// 激励视频广告
            self.customEventClass = NSClassFromString(@"MobiPrivateRewardedVideoCustomEvent");
        }
            break;
        case MobiAdTypeFullScreenVideo: {
            /// 全屏视频广告
            self.customEventClass = NSClassFromString(@"MobiPrivateFullScreenVideoCustomEvent");
        }
            break;
            
        default:
            break;
    }
}

- (NSArray <NSURL *> *)URLsFromArray:(NSArray *)URLStrings {
    if (URLStrings == nil) {
        return nil;
    }

    // Convert the strings into NSURLs and save in a new array
    NSMutableArray <NSURL *> * URLs = [NSMutableArray arrayWithCapacity:URLStrings.count];
    for (NSString * URLString in URLStrings) {
        // @c URLWithString may return @c nil, so check before appending to the array
        NSURL * URL = [NSURL URLWithString:URLString];
        if (URL != nil) {
            [URLs addObject:URL];
        }
    }

    return URLs.count > 0 ? URLs : nil;
}

- (BOOL)hasPreferredSize {
    return (self.preferredSize.width > 0 && self.preferredSize.height > 0);
}

- (NSString *)adResponseHTMLString {
    if (!_adResponseHTMLString) {
        self.adResponseHTMLString = [[NSString alloc] dencode:self.bannerConfigData.ad];
    }

    return _adResponseHTMLString;
}

@end
