//
//  MEAdNetworkManager.m
//  MEzzPedometer
//
//  Created by 刘峰 on 2020/6/30.
//  Copyright © 2020 刘峰. All rights reserved.
//

#import "MEAdNetworkManager.h"
#import "MEBaseAdapter.h"
#import <objc/Message.h>

@implementation MEAdNetworkModel
@end

@implementation MEAdNetworkManager

+ (instancetype)sharedInstance {
    static MEAdNetworkManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [MEAdNetworkManager new];
    });
    return manager;
}

+ (void)configAdNetworksWithConfigInfo:(NSArray <MEConfigInfo *>*)infoArr {
    MEAdNetworkManager *sharedInstance = [MEAdNetworkManager sharedInstance];
    for (int i = 0; i < infoArr.count; i++) {
        MEConfigInfo *info = infoArr[i];
        // 头条穿山甲
        if ([info.sdk isEqualToString:@"tt"]) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.agentType = MEAdAgentTypeBUAD;
            model.adapterClass = NSClassFromString(@"MEBUADAdapter");
            [sharedInstance.adNetworks addObject:model];
        }

        // 广点通
        if ([info.sdk isEqualToString:@"gdt"]) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.agentType = MEAdAgentTypeGDT;
            model.adapterClass = NSClassFromString(@"MEGDTAdapter");
            [sharedInstance.adNetworks addObject:model];
        }

        // 快手
        if ([info.sdk isEqualToString:@"ks"]) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.agentType = MEAdAgentTypeKS;
            model.adapterClass = NSClassFromString(@"MEKSAdapter");
            [sharedInstance.adNetworks addObject:model];
        }
        
        // valpub
        if ([info.sdk isEqualToString:@"gdt2"]) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.agentType = MEAdAgentTypeValpub;
            model.adapterClass = NSClassFromString(@"MEValpubAdapter");
            [sharedInstance.adNetworks addObject:model];
        }
        
        // 谷歌
        if ([info.sdk isEqualToString:@"admob"]) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.agentType = MEAdAgentTypeAdmob;
            model.adapterClass = NSClassFromString(@"MEAdombAdapter");
            [sharedInstance.adNetworks addObject:model];
        }
        
        // Facebook
        if ([info.sdk isEqualToString:@"fb"]) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.agentType = MEAdAgentTypeFacebook;
            model.adapterClass = NSClassFromString(@"MEFBAdapter");
            [sharedInstance.adNetworks addObject:model];
        }
        
        // Mobipub
        if ([info.sdk isEqualToString:@"mobisdk"]) {
            MEAdNetworkModel *model = [MEAdNetworkModel new];
            model.appid = info.appid;
            model.sdk = info.sdk;
            model.agentType = MEAdAgentTypeMobiSDK;
            model.adapterClass = NSClassFromString(@"MEMobipubAdapter");
            [sharedInstance.adNetworks addObject:model];
        }
    }
}

/// 初始化各广告平台
+ (BOOL)launchAdNetwork {
    // 从配置中取出广告平台模型,用适配器进行相应的初始化
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        Class adapterClass = model.adapterClass;
//        SEL launchSEL = NSSelectorFromString(@"launchAdPlatformWithAppid:");
//        objc_msgSend(adapterClass, launchSEL, model.appid);
        [adapterClass launchAdPlatformWithAppid:model.appid];
    }
    
    return YES;
}

/// 根据广告平台类型获取广告平台缩写
/// @param agentType 广告平台类型
+ (NSString *)getNetworkNameFromAgentType:(MEAdAgentType)agentType {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.agentType == agentType) {
            return model.sdk;
        }
    }
    
    return nil;
}

/// 根据广告平台类型获取对应的appid
/// @param agentType 广告平台类型
+ (NSString *)getAppidFromAgentType:(MEAdAgentType)agentType {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.agentType == agentType) {
            return model.appid;
        }
    }
    
    return nil;
}

/// 根据广告名称缩写获取广告平台类型
/// @param sdk 广告平台的名称缩写
+ (MEAdAgentType)getAgentTypeFromNetworkName:(NSString *)sdk {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.sdk == sdk) {
            return model.agentType;
        }
    }
    
    return MEAdAgentTypeNone;
}

/// 根据广告平台类型获取对应的适配器
/// @param agentType 广告平台类型
+ (Class)getAdapterClassFromAgentType:(MEAdAgentType)agentType {
    for (MEAdNetworkModel *model in MEAdNetworkManager.sharedInstance.adNetworks) {
        if (model.agentType == agentType) {
            return model.adapterClass;
        }
    }
    
    return Nil;
}

// MARK: - Getter
- (NSMutableArray<MEAdNetworkModel *> *)adNetworks {
    if (!_adNetworks) {
        _adNetworks = [NSMutableArray array];
    }
    return _adNetworks;
}

@end
