//
//  AssignStrategy.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy.h"
#import "MobiConfig.h"
#import "MobiAdapterConfiguration.h"

@implementation StrategyResultModel
@end

@implementation AssignStrategy

- (NSArray <MobiConfig *>*)getExecuteConfigurationWithListInfo:(MEConfigList *)listInfo sceneId:(NSString *)sceneId adType:(MobiAdType)adType {
    return nil;
}

/// 获取各广告平台对应的 custom event 实现类
- (Class)getClassByAdType:(MobiAdType)adType adapterProvider:(id<MobiAdapterConfiguration>)adapterProvider {
    if (adType == MobiAdTypeSplash) {
        return [adapterProvider getSplashCustomEvent];
    } else if (adType == MobiAdTypeBanner) {
        return [adapterProvider getBannerCustomEvent];
    } else if (adType == MobiAdTypeFeed) {
        return [adapterProvider getFeedCustomEvent];
    } else if (adType == MobiAdTypeInterstitial) {
        return [adapterProvider getInterstitialCustomEvent];
    } else if (adType == MobiAdTypeRewardedVideo) {
        return [adapterProvider getRewardedVideoCustomEvent];
    } else if (adType == MobiAdTypeFullScreenVideo) {
        return [adapterProvider getFullscreenCustomEvent];
    }
    
    return NULL;
}

/// 当指定了加载广告的平台时,统一调这个方法
- (NSArray <StrategyResultModel *>*)getExecuteAdapterModelsWithTargetPlatformType:(MEAdAgentType)platformType
                                                                         listInfo:(MEConfigList *)listInfo
                                                                          sceneId:(NSString *)sceneId {
    if (![listInfo.posid isEqualToString:sceneId]) {
        return nil;
    }
    
    if (platformType > MEAdAgentTypeNone && platformType < MEAdAgentTypeCount) {
        // 若指定了广告平台,则直接返回该平台的posid等信息
        MobiConfig *configuration = [[MobiConfig alloc] init];
        for (int i = 0; i < listInfo.network.count; i++) {
            MEConfigNetwork *network = listInfo.network[i];
            if ([network.sdk isEqualToString:[MEAdNetworkManager getNetworkNameFromAgentType:platformType]]) {
                configuration.adUnitId = network.parameter.posid;
                configuration.sceneId = sceneId;
                id<MobiAdapterConfiguration> adapterProvider = MEAdNetworkManager.sharedInstance.initializedAdapters[network.sdk];
//                return [MEAdNetworkManager getAdapterClassFromAgentType:platformType];
                return @[configuration];
            }
        }
    }
    
    return nil;
}

@end
