//
//  MEAdLogModel.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/19.
//

#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEAdLogModel : RLMObject

// log日期时间戳,精确到天
@property (nonatomic, copy) NSString *day;
// log时间戳,精确到分
@property (nonatomic, copy) NSString *time;
// 设备deviceId
@property (nonatomic, copy) NSString *deviceid;
// 应用平台
@property (nonatomic, copy) NSString *platform;
// SDK版本号
@property (nonatomic, copy) NSString *sdkv;
// 渠道号,定死appstore
@property (nonatomic, copy) NSString *channel_no;

/// 以下为必须手动填
// 广告渠道 tt,gdt
@property (nonatomic, copy) NSString *network;
// 自有广告id
@property (nonatomic, copy) NSString *posid;
// 1展示 0未展示
@property (nonatomic, copy) NSString *pv;
// 1点击 0未点击
@property (nonatomic, copy) NSString *click;

//根据保存对象
+ (void)saveLogModelToRealm:(MEAdLogModel *)logModel;
//查询所有日志
+ (RLMResults<MEAdLogModel *> *)queryAllLogModels;
//查询过期日志
+ (RLMResults<MEAdLogModel *> *)queryLogModelsWithLevel:(NSString *)level beforeDays:(NSInteger)days;

//检测各类型日志条数，并上传服务器
+ (void)checkLogsAndUploadToServer;
//开机上传日志
+ (void)uploadLogsWhenLaunched;

//批量删除日志
+ (void)deleteLogs:(RLMResults *)logs;
//删除所有日志
+ (void)deleteAllLogs;

//批量保存日志
+ (void)saveLogs:(RLMResults *)logs;
//网络上传日志-RLMResults
+ (void)uploadLogsToServer:(RLMResults *)logs Finished:(void (^)(BOOL success,NSError *error))finished;
//网络上传日志-使用NSArray
+ (void)uploadLogsToServerWithArray:(NSArray *)logs Finished:(void (^)(BOOL success,NSError *error))finished;

@end

NS_ASSUME_NONNULL_END
