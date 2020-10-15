//
//  MELogTracker.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/10/14.
//

#import "MELogTracker.h"
#import "MobiGlobalConfig.h"
#import "MobiHTTPNetworkSession.h"
#import "MPError.h"

#define kLimit 5
#define kLogUploadCount 20

//开机传送日志中
static BOOL launchLogsUploading = NO;
//前台传送日志中
static BOOL logsUploading = NO;

@implementation MELogTracker

//配置 log 的基础数据
+ (MEAdLogModel *)configBasicLogData:(MEAdLogModel *)logModel {
    if (!logModel.day) {// 天时间戳
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        logModel.day = [formatter stringFromDate:[NSDate date]];
    }

    if (!logModel.time) {// 分时间戳
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
        logModel.time = [formatter stringFromDate:[NSDate date]];
    }

    if (!logModel.appid) { // 聚合平台的appid
        logModel.appid = [MobiGlobalConfig sharedInstance].platformAppid;
    }

    // 其他数据理应必传
    return logModel;
}

+ (void)uploadImmediatelyWithLogModels:(NSArray <MEAdLogModel *>*)logs {
    //如果正在上传中，就不检测
    if (logsUploading == YES || launchLogsUploading == YES) {
        return;
    }

    //上传数据
    logsUploading = YES;  //标记正在上传
    [self uploadImmediatlyWithLogs:logs postTimes:1 finished:^{
        //修改传输标记
        logsUploading = NO;
    }];
}

+ (void)uploadImmediatlyWithLogs:(NSArray <MEAdLogModel *>*)logs postTimes:(NSInteger)postCount finished:(void (^)(void))finished {
    //创建线程组
    dispatch_group_t group = dispatch_group_create();

    //多个请求.+1是为了把多余的不够kLimit条的数据也一并发送了
    for (int i = 0; i < postCount+1;i++ ) {
        //如果上传次数超过10条,则暂停上传,下次再传
        if (i == 9) {
            return;
        }
        //按段取出数据上传
        NSMutableArray *arrayReportUrl = [NSMutableArray array];
        NSMutableArray *arrayDeveloperUrl = [NSMutableArray array];

        for (int j = i*kLimit; j < kLimit*(i+1); j++ ) {
            if (j < logs.count) {
                MEAdLogModel *logModel = [logs objectAtIndex:j];
                if ([self isReportUrlLog:logModel]) {
                    [arrayReportUrl addObject:logModel];
                } else {
                    [arrayDeveloperUrl addObject:logModel];
                }
            }
        }

        // report日志上传
        if (arrayReportUrl.count) {
            //标记进入
            dispatch_group_enter(group);
            //发起请求
            [self uploadLogsToServerWithArray:arrayReportUrl URL:[MobiGlobalConfig sharedInstance].adLogUrl Finished:^(BOOL success, NSError * _Nonnull error) {
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

        // developer日志上传
        if (arrayDeveloperUrl.count) {
            //标记进入
            dispatch_group_enter(group);
            //发起请求
            [self uploadLogsToServerWithArray:arrayDeveloperUrl URL:[MobiGlobalConfig sharedInstance].developerUrl Finished:^(BOOL success, NSError * _Nonnull error) {
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

/// 返回YES用reportUrl上传,否则用developerUrl上传
+ (BOOL)isReportUrlLog:(MEAdLogModel *)log {
    switch (log.event) {
        case AdLogEventType_Request:
        case AdLogEventType_Show:
        case AdLogEventType_Load:
        case AdLogEventType_Click:
            return YES;
    }
    return NO;
}

//网络上传日志-使用NSArray
+ (void)uploadLogsToServerWithArray:(NSArray *)logs URL:(NSString *)url Finished:(void (^)(BOOL success,NSError *error))finished {
    if (logs.count == 0) {
        finished(nil,nil);
        return;
    }

    //设置参数
    NSMutableArray *arrayM = [NSMutableArray array];
    for (int i = 0; i < logs.count; i++) {
        MEAdLogModel *logModel = [self  configBasicLogData:[logs objectAtIndex:i]];
        NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
        if (logModel.day) {
            dicM[@"day"] = logModel.day;
        }
        if (logModel.time) {
            dicM[@"time"] = logModel.time;
        }
        if (logModel.appid) {
            dicM[@"appid"] = logModel.appid;
        }

        if (logModel.event) {
            dicM[@"event"] = @(logModel.event);
        }
        if (logModel.st_t) {
            dicM[@"st_t"] = @(logModel.st_t);
        }
        if (logModel.so_t) {
            dicM[@"so_t"] = @(logModel.so_t);
        }
        if (logModel.posid) {
            dicM[@"posid"] = logModel.posid;
        }
        if (logModel.network) {
            dicM[@"network"] = logModel.network;
        }
        if (logModel.tk) {
            dicM[@"tk"] = logModel.tk;
        }

        if (logModel.type) {
            dicM[@"type"] = @(logModel.type);
        }
        if (logModel.code) {
            dicM[@"code"] = @(logModel.code);
        }
        if (logModel.msg) {
            dicM[@"msg"] = logModel.msg;
        }
        if (logModel.debug) {
            dicM[@"debug"] = logModel.debug;
        }
        [arrayM addObject:dicM];
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"content"] = arrayM;

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request = [self setHTTPHeaderWithRequest:request];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];

    // 请求配置
    __weak __typeof__(self) weakSelf = self;
    [MobiHTTPNetworkSession startTaskWithHttpRequest:request responseHandler:^(NSData * _Nonnull data, NSHTTPURLResponse * _Nonnull response) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf didFinishLoadingWithData:data finished:finished];
    } errorHandler:^(NSError * _Nonnull error) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf didFailWithError:error finished:finished];
    }];
}

// 设置请求头
+ (NSMutableURLRequest *)setHTTPHeaderWithRequest:(NSMutableURLRequest *)request {
    NSMutableURLRequest *mutReq = [request mutableCopy];

    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    headerParams[@"crr"] = [MEAdHelpTool deviceSupplier];
    headerParams[@"uud"] = [MEAdHelpTool uuid];
    headerParams[@"med"] = @"";
    headerParams[@"fad"] = [MEAdHelpTool idfa];
    headerParams[@"oad"] = @"";
    headerParams[@"mk"] = @"apple";
    headerParams[@"md"] = [MEAdHelpTool getDeviceModel];
    headerParams[@"osv"] = [MEAdHelpTool systemVersion];
    headerParams[@"os"] = @"ios";
    headerParams[@"lan"] = [MEAdHelpTool localIdentifier];
    headerParams[@"ver"] = [MEAdHelpTool getSDKVersion];
    headerParams[@"lon"] = [MEAdHelpTool lon];
    headerParams[@"lat"] = [MEAdHelpTool lat];
    headerParams[@"nt"] = [MEAdHelpTool network];

    [headerParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![mutReq valueForHTTPHeaderField:key]) {
            [mutReq setValue:obj forHTTPHeaderField:key];
        }
    }];

    return mutReq;
}

#pragma mark - Handlers

+ (void)didFailWithError:(NSError *)error finished:(void (^)(BOOL success,NSError *error))finished {
    // Do not record a logging event if we failed.
    logsUploading = NO;
    DLog(@"日志上传失败 error = %@", error);
    finished(NO, error);
}

+ (void)didFinishLoadingWithData:(NSData *)data finished:(void (^)(BOOL success,NSError *error))finished {
    logsUploading = NO;
    
    NSError * error = nil;
//    NSDictionary * responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) {
        NSError * parseError = [NSError adResponseFailedToParseWithError:error];
        [self didFailWithError:parseError finished:finished];
        return;
    }
    
    finished(YES, nil);
}

@end
