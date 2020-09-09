//
//  MobiLaunchAdConst.h
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/28.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef DEBUG
#define MobiLaunchAdLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define MobiLaunchAdLog(...)
#endif

#define MobiLaunchAdDeprecated(instead) __attribute__((deprecated(instead)))

#define MobiWeakSelf __weak typeof(self) weakSelf = self;

#define Mobi_ScreenW    [UIScreen mainScreen].bounds.size.width
#define Mobi_ScreenH    [UIScreen mainScreen].bounds.size.height

#define Mobi_IPHONEX  ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define Mobi_IPHONEXR    ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) : NO)
#define Mobi_IPHONEXSMAX    ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)
#define Mobi_FULLSCREEN ((Mobi_IPHONEX || Mobi_IPHONEXR || Mobi_IPHONEXSMAX) ? YES : NO)

///是否是动图数据
#define MobiISGIFTypeWithData(data)\
({\
BOOL result = NO;\
if(!data) result = NO;\
uint8_t c;\
[data getBytes:&c length:1];\
if(c == 0x47) result = YES;\
(result);\
})

///是否是视频路径
#define MobiISVideoTypeWithPath(path)\
({\
BOOL result = NO;\
if([path hasSuffix:@".mp4"])  result =  YES;\
(result);\
})

///是否是url
#define MobiISURLString(string)  ([string hasPrefix:@"https://"] || [string hasPrefix:@"http://"]) ? YES:NO

///取出路径下的data
#define MobiDataWithFileName(name)\
({\
NSData *data = nil;\
NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];\
if([[NSFileManager defaultManager] fileExistsAtPath:path]){\
    data = [NSData dataWithContentsOfFile:path];\
}\
(data);\
})

///移除view
#define REMOVE_FROM_SUPERVIEW_SAFE(view) if(view)\
{\
[view removeFromSuperview];\
view = nil;\
}

///移除timer
#define DISPATCH_SOURCE_CANCEL_SAFE(time) if(time)\
{\
dispatch_source_cancel(time);\
time = nil;\
}

/** 存储的图片的url的key */
UIKIT_EXTERN NSString *const MobiCacheImageUrlStringKey;
//UIKIT_EXTERN NSString *const XHCacheVideoUrlStringKey;
/** 数据等待时间已到 */
UIKIT_EXTERN NSString *const MobiLaunchAdWaitDataDurationArriveNotification;
/** GIFImageCycleOnce = YES(GIF不循环)时, GIF动图播放完成通知 */
UIKIT_EXTERN NSString *const MobiLaunchAdGIFImageCycleOnceFinishNotification;
/** 广告详情页的通知 */
UIKIT_EXTERN NSString *const MobiLaunchAdDetailPageWillShowNotification;
UIKIT_EXTERN NSString *const MobiLaunchAdDetailPageDidShowNotification;
UIKIT_EXTERN NSString *const MobiLaunchAdDetailPageDismissNotification;
UIKIT_EXTERN NSString *const MobiLaunchAdDetailPageWillDismissNotification;
/** 刘海屏底部横条隐藏 */
UIKIT_EXTERN BOOL MobiLaunchAdPrefersHomeIndicatorAutoHidden;
