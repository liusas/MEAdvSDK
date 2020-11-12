//
//  AssignStrategy1.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy1.h"

@implementation AssignStrategy1

- (NSArray <MobiConfig *>*)getExecuteConfigurationWithListInfo:(MEConfigList *)listInfo sceneId:(NSString *)sceneId adType:(MobiAdType)adType {
    if (![listInfo.posid isEqualToString:sceneId]) {
        return nil;
    }
    
    NSMutableArray *arr = [NSMutableArray array];
    // 串行顺序,先将数组按优先级排序后,返回整个数组
    if (listInfo.network.count) {
        for (int i = 0; i < listInfo.network.count; i++) {
            MEConfigNetwork *network = listInfo.network[i];
            MobiConfig *configuration = [[MobiConfig alloc] init];
            configuration.adUnitId = network.parameter.posid;
            configuration.sceneId = sceneId;
            configuration.adType = adType;
            configuration.sortType = 1;
            configuration.networkName = network.sdk;
            configuration.ntName = network.ntName;
            id<MobiAdapterConfiguration> adapterProvider = MEAdNetworkManager.sharedInstance.initializedAdapters[network.sdk];
            configuration.adapterProvider = adapterProvider;
            
            // 若有执行广告的 custom event,则添加 configuration 到数组
            if ([self getClassByAdType:adType adapterProvider:adapterProvider] != NULL) {
                configuration.customEventClass = [self getClassByAdType:adType adapterProvider:adapterProvider];
                [arr addObject:configuration];
            }
        }
    }
    
    if (arr.count) {
        return arr;
    }
    
    return nil;
}

@end
