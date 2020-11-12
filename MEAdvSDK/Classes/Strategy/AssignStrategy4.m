//
//  AssignStrategy4.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy4.h"
#import "StrategyFactory.h"

@implementation AssignStrategy4

- (NSArray <MobiConfig *>*)getExecuteConfigurationWithListInfo:(MEConfigList *)listInfo sceneId:(NSString *)sceneId adType:(MobiAdType)adType {
    if (![listInfo.posid isEqualToString:sceneId]) {
        return nil;
    }
    
    NSMutableArray *arr = [NSMutableArray array];
    // 先看该广告位是否需要控制频次,此处采用策略是,将策略数组中的广告标识按优先级顺序排序,最终返回排序后的 configuration 数组
    if ([StrategyFactory sharedInstance].sceneIdFrequencyDic[sceneId] && listInfo.orderParameter.count && listInfo.sortType.intValue == 4) {
        // 如果这里面还是字符串,证明没有按照数组下标重设 orderParameter
        if ([listInfo.orderParameter.firstObject isKindOfClass:[NSString class]]) {
            return nil;
        }
        
        // orderParameter 中存储的是对应 listInfo.network 数组的下标,所以我们只需要取出 sceneIdFrequencyDic 的 orderParameter 的下标即可得到 listInfo.network 数组的下标
        NSInteger currentIndex = [[StrategyFactory sharedInstance].sceneIdFrequencyDic[sceneId] intValue];
        int i = 0;// 作为循环的次数记录
        while (i < listInfo.network.count) {
             NSInteger index = [listInfo.orderParameter[(currentIndex + i) % listInfo.network.count] integerValue];
            if (index < listInfo.network.count) {
                MEConfigNetwork *network = listInfo.network[index];
                MobiConfig *configuration = [[MobiConfig alloc] init];
                configuration.adUnitId = network.parameter.posid;
                configuration.sceneId = sceneId;
                configuration.adType = adType;
                configuration.sortType = 4;
                configuration.networkName = network.sdk;
                configuration.ntName = network.ntName;
                id<MobiAdapterConfiguration> adapterProvider = MEAdNetworkManager.sharedInstance.initializedAdapters[network.sdk];
                configuration.adapterProvider = adapterProvider;
                
                if ([self getClassByAdType:adType adapterProvider:adapterProvider] != NULL) {
                    configuration.customEventClass = [self getClassByAdType:adType adapterProvider:adapterProvider];
                    [arr addObject:configuration];
                }
            }
            i++;
        }
    }
    
    if (arr.count == 0) {
        return nil;
    }
    
    return arr;
}

@end
