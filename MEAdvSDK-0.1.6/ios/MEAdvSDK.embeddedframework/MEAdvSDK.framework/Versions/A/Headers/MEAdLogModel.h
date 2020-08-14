//
//  MEAdLogModel.h
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/19.
//

#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AdLogEventType) {
    AdLogEventType_Request = 10, // 请求
    AdLogEventType_Load = 20,    // 加载
    AdLogEventType_Show = 30,    // 展示
    AdLogEventType_Click = 40,   // 点击
    AdLogEventType_Fault = 100,  // 错误
};

typedef NS_ENUM(NSInteger, AdLogFaultType) {
    AdLogFaultType_Cancel = 10000,              // 取消
    AdLogFaultType_Expire = 10001,              // 超时
    AdLogFaultType_Normal = 10002,              // 普通出错（没到进行渲染，加载出错等）
    AdLogFaultType_Render = 10003,              // 渲染出错（load成功了，渲染出错）
    AdLogFaultType_EmptyData = 10004,           // 获取到了广告时返回的结构是空的
    AdLogFaultType_Wrongid = 10005,             // 传进来的 codeid 不正确 [ debug有值 ]
    AdLogFaultType_SortTypeUnSupport = 10006,   // 本地不支持该策略 [ debug有值 ]
    AdLogFaultType_NoneSortType = 10007,        // 策略获取为空，就是数据里面的给了空策略 [ debug有值 ]
};

typedef NS_ENUM(NSInteger, AdLogAdType) {
    AdLogAdType_Splash = 1,         // 开屏
    AdLogAdType_Interstitial = 2,   // 插屏
    AdLogAdType_Feed = 3,           // 信息流
    AdLogAdType_RewardVideo = 4,    // 激励视频
    AdLogAdType_FullVideo = 5,      // 全屏
    
};

@interface MEAdLogModel : RLMObject

/***************以下为默认填写***************/
/// log日期时间戳,精确到天
@property (nonatomic, copy) NSString *day;
/// log时间戳,精确到分
@property (nonatomic, copy) NSString *time;
/// 聚合sdk给用户使用的appid
@property (nonatomic, copy) NSString *appid;

/***************以下为必须手动填***************/
/// 请求 10, 填充 20, 展示30, 点击 40
@property (nonatomic, assign) NSInteger event;
/// 对应的三方sdk平台的类型：如：tt，gdt
@property (nonatomic, copy) NSString *network;
/// 聚合sdk给用户使用的postid
@property (nonatomic, copy) NSString *posid;
/// 对应的广告类型：如：1（开屏）2（插入广告）3（本地信息流）4（激励视频）5（全屏视频）
@property (nonatomic, assign) NSInteger st_t;
/// 服务器下发的广告策略类型：如：1（按照顺序来）4（按照服务器返回的固定顺序加载对应平台的广告）5（广告一起请求显示最先回来的）
@property (nonatomic, assign) NSInteger so_t;
/// 追踪用户的一次请求，然后可以进行一次广告请求的连起来分析，策略暂时是根据：posid+sortType+"mobi"+当前时间戳  hash（算法是md5）的一个值
@property (nonatomic, copy) NSString *tk;
/// 错误类型：如：10000 （取消）10001（超时）10002（普通错误）
@property (nonatomic, assign) NSInteger type;
/// 出错的code，默认为0，为三方sdk报错出现的
@property (nonatomic, assign) NSInteger code;
/// 三方sdk出错出现，三方sdk给的message
@property (nonatomic, copy) NSString *msg;
/// 非三方sdk出现的错误，默认没有code，传个message，进行聚合sdk分析使用
@property (nonatomic, copy) NSString *debug;

//根据保存对象
+ (void)saveLogModelToRealm:(MEAdLogModel *)logModel;
//查询所有日志
+ (RLMResults<MEAdLogModel *> *)queryAllLogModels;
//查询过期日志
//+ (RLMResults<MEAdLogModel *> *)queryLogModelsWithLevel:(NSString *)level beforeDays:(NSInteger)days;

//检测各类型日志条数，并上传服务器
+ (void)checkLogsAndUploadToServer;
//开机上传日志
+ (void)uploadLogsWhenLaunched;
//立即上传
+ (void)uploadImmediately;

//批量删除日志
+ (void)deleteLogs:(RLMResults *)logs;
//删除所有日志
+ (void)deleteAllLogs;

//批量保存日志
+ (void)saveLogs:(RLMResults *)logs;
//网络上传日志-RLMResults
+ (void)uploadLogsToServer:(RLMResults *)logs URL:(NSString *)url Finished:(void (^)(BOOL success,NSError *error))finished;
//网络上传日志-使用NSArray
+ (void)uploadLogsToServerWithArray:(NSArray *)logs URL:(NSString *)url Finished:(void (^)(BOOL success,NSError *error))finished;

@end

NS_ASSUME_NONNULL_END
