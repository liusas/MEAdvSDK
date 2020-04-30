//
//  MEAdLogModel.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/19.
//

#import "MEAdLogModel.h"
#import "NBLHTTPManager.h"
#import "MEConfigManager.h"
#import "MEAdHelpTool.h"

#define kLimit 5
#define kLogUploadCount 20

//开机传送日志中
static BOOL launchLogsUploading = NO;
//前台传送日志中
static BOOL logsUploading = NO;

@implementation MEAdLogModel

// MARK: - 日志配置处理
//检测各类型日志条数，并上传服务器
+ (void)checkLogsAndUploadToServer {
    //如果正在上传中，就不检测
    if (logsUploading == YES || launchLogsUploading == YES) {
        return;
    }
    
    //查出所有数据
    RLMResults<MEAdLogModel *> *logs = [MEAdLogModel queryAllLogModels];
    //数量满足条件，就需要上传
    if (logs.count >= kLogUploadCount) {
        //上传数据
        logsUploading = YES;  //标记正在上传
        [self uploadLogsToServer:logs finished:^{
            //修改传输标记
            logsUploading = NO;
        }];
    }
}

//开机上传日志
+ (void)uploadLogsWhenLaunched {
    //查出数据
    RLMResults<MEAdLogModel *> *logs = [MEAdLogModel queryAllLogModels];
    //标记正在传输中
    launchLogsUploading = YES;
    
    //数量满足条件，就需要上传(开辟多条请求)
    if (logs.count >= kLogUploadCount) {
        //上传数据
        [self uploadLogsToServer:logs finished:^{
            //标记传输结束
            launchLogsUploading = NO;
        }];
    }
}

// MARK: - 保存日志
//批量保存日志
+ (void)saveLogs:(RLMResults *)logs {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObjects:logs];
    [realm commitWriteTransaction];
}

//根据保存对象
+ (void)saveLogModelToRealm:(MEAdLogModel *)logModel {
    if (!logModel.day) {// 天时间戳
        logModel.day = [MEAdHelpTool getDayStr];
    }
    
    if (!logModel.time) {// 分时间戳
//        logModel.time = [MEAdHelpTool getTimeStr];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
        logModel.time = [formatter stringFromDate:[NSDate date]];
    }
    
    if (!logModel.deviceid) {// 设备id
        logModel.deviceid = [MEConfigManager sharedInstance].deviceId;
    }
    
    if (!logModel.platform) {// 平台就是iOS
        logModel.platform = @"iOS";
    }
    
    if (!logModel.sdkv) {// SDK版本号
        logModel.sdkv = @"1.0.0";
    }
    
    if (!logModel.channel_no) {// 渠道为appstore
        logModel.channel_no = @"appstore";
    }
    
    // 其他数据理应必传
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:logModel];
    [realm commitWriteTransaction];
}

// MARK: - 查询日志
//查询所有日志
+ (RLMResults<MEAdLogModel *> *)queryAllLogModels {
    RLMResults<MEAdLogModel *> *logs = [MEAdLogModel allObjects];
    return logs;
}

// MARK: - 删除日志
//批量删除日志
+ (void)deleteLogs:(RLMResults *)logs {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteObjects:logs];
    [realm commitWriteTransaction];
}

//删除所有日志
+ (void)deleteAllLogs {
    RLMResults *allLogs = [MEAdLogModel allObjects];
    [self deleteLogs:allLogs];
}

// MARK: - 上传日志
//上传日志到服务器
+ (void)uploadLogsToServer:(RLMResults *)logs finished:(void (^)())finished {
    //切分日志，每kLimit条发一个请求
    NSInteger postCount = logs.count/kLimit;
    //创建线程组
    dispatch_group_t group = dispatch_group_create();
    DLog(@"广告日志数量 = %zd条",logs.count);
    if (postCount) {
        //多个请求
        for (int i = 0; i < postCount+1;i++ ) {
            //如果上传次数超过10条,则暂停上传,下次再传
            if (i == 9) {
                return;
            }
            //按段取出数据上传
            NSMutableArray *arrayM = [NSMutableArray array];
            for (int j = i*kLimit; j < kLimit*(i+1); j++ ) {
                if (j < logs.count) {
                    MEAdLogModel *logModel = [logs objectAtIndex:j];
                    [arrayM addObject:logModel];
                }
            }
            //标记进入
            dispatch_group_enter(group);
            //发起请求
            [MEAdLogModel uploadLogsToServerWithArray:arrayM Finished:^(BOOL success, NSError * _Nonnull error) {
                //标记离开
                dispatch_group_leave(group);
                if (success) {
                    //上传成功，删除日志
                    DLog(@"上传广告日志成功");
                } else {
                    //上传失败
                    DLog(@"上传日志失败");
                }
            }];
        }
    }
    //所有线程都结束后，接收通知
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        //修改传输标记
        finished();
    });
}

//网络上传日志-使用rlmresults
+ (void)uploadLogsToServer:(RLMResults *)logs Finished:(void (^)(BOOL success,NSError *error))finished {
    if (logs.count == 0) {
        finished(nil,nil);
        return;
    }

    //设置参数
    NSMutableArray *arrayM = [NSMutableArray array];
    for (int i = 0; i < logs.count; i++) {
        MEAdLogModel *logModel = [logs objectAtIndex:i];
        NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
        if (logModel.day) {
            dicM[@"day"] = logModel.day;
        }
        if (logModel.time) {
            dicM[@"time"] = logModel.time;
        }
        if (logModel.deviceid) {
            dicM[@"deviceid"] = logModel.deviceid;
        }
        if (logModel.platform) {
            dicM[@"platform"] = logModel.platform;
        }
        if (logModel.sdkv) {
            dicM[@"sdkv"] = logModel.sdkv;
        }
        if (logModel.channel_no) {
            dicM[@"channel_no"] = logModel.channel_no;
        }
        if (logModel.network) {
            dicM[@"network"] = logModel.network;
        }
        if (logModel.posid) {
            dicM[@"posid"] = logModel.posid;
        }
        if (logModel.pv) {
            dicM[@"pv"] = logModel.pv;
        }
        if (logModel.click) {
            dicM[@"click"] = logModel.click;
        }
        [arrayM addObject:dicM];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"content"] = arrayM;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[MEConfigManager sharedInstance].adLogUrl]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    
    [[NBLHTTPManager sharedManager] requestObject:NBLResponseObjectType_JSON withRequest:request param:nil andResult:^(NSHTTPURLResponse *httpResponse, id responseObject, NSError *error, NSDictionary *dicParam) {
        if (error) {
            DLog(@"请求url: %@ 请求参数: %@", [MEConfigManager sharedInstance].adLogUrl, params);
            DLog(@"错误数据：%@", error);
            finished(NO, error);
            return;
        }
        
        if ([responseObject[@"code"] isEqualToString:@"200"]) {
            // 日志上报成功
            [MEAdLogModel deleteLogs:logs];
            finished(YES, nil);
        }
        
    }];
}

//网络上传日志-使用NSArray
+ (void)uploadLogsToServerWithArray:(NSArray *)logs Finished:(void (^)(BOOL success,NSError *error))finished {
    if (logs.count == 0) {
        finished(nil,nil);
        return;
    }

    //设置参数
    NSMutableArray *arrayM = [NSMutableArray array];
    for (int i = 0; i < logs.count; i++) {
        MEAdLogModel *logModel = [logs objectAtIndex:i];
        NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
        if (logModel.day) {
            dicM[@"day"] = logModel.day;
        }
        if (logModel.time) {
            dicM[@"time"] = logModel.time;
        }
        if (logModel.deviceid) {
            dicM[@"deviceid"] = logModel.deviceid;
        }
        if (logModel.platform) {
            dicM[@"platform"] = logModel.platform;
        }
        if (logModel.sdkv) {
            dicM[@"sdkv"] = logModel.sdkv;
        }
        if (logModel.channel_no) {
            dicM[@"channel_no"] = logModel.channel_no;
        }
        if (logModel.network) {
            dicM[@"network"] = logModel.network;
        }
        if (logModel.posid) {
            dicM[@"posid"] = logModel.posid;
        }
        if (logModel.pv.length > 0) {
            dicM[@"pv"] = @([logModel.pv integerValue]);
        }
        if (logModel.click.length > 0) {
            dicM[@"click"] = @([logModel.click integerValue]);
        }
        [arrayM addObject:dicM];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"content"] = arrayM;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[MEConfigManager sharedInstance].adLogUrl]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    
    [[NBLHTTPManager sharedManager] requestObject:NBLResponseObjectType_JSON withRequest:request param:nil andResult:^(NSHTTPURLResponse *httpResponse, id responseObject, NSError *error, NSDictionary *dicParam) {
        if (error) {
            DLog(@"请求url: %@ 请求参数: %@", [MEConfigManager sharedInstance].adLogUrl, params);
            DLog(@"错误数据：%@", error);
            finished(NO, error);
            return;
        }
        
        if ([responseObject[@"code"] isEqualToString:@"200"]) {
            // 日志上报成功
            [MEAdLogModel deleteLogs:logs];
            finished(YES, nil);
        }
        
    }];
}

@end
