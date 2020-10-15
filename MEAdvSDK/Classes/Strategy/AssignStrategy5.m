//
//  AssignStrategy5.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/7/1.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "AssignStrategy5.h"

@implementation AssignStrategy5

- (NSArray <MobiConfig *>*)getExecuteConfigurationWithListInfo:(MEConfigList *)listInfo sceneId:(NSString *)sceneId adType:(MobiAdType)adType {
    if (![listInfo.posid isEqualToString:sceneId]) {
        return nil;
    }
    
    NSMutableArray *arr = [NSMutableArray array];
    // 并行策略,则将该数组下的所有 configuration 都返回
    if (listInfo.network.count) {
        for (int i = 0; i < listInfo.network.count; i++) {
            MEConfigNetwork *network = listInfo.network[i];
            MobiConfig *configuration = [[MobiConfig alloc] init];
            configuration.adUnitId = network.parameter.posid;
            configuration.sceneId = sceneId;
            configuration.adType = adType;
            configuration.sortType = 5;
            configuration.networkName = network.sdk;
            id<MobiAdapterConfiguration> adapterProvider = MEAdNetworkManager.sharedInstance.initializedAdapters[network.sdk];
            configuration.adapterProvider = adapterProvider;
            
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
