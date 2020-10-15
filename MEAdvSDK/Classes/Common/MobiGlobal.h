//
//  MobiGlobal.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef Mobi_ANIMATED
#define Mobi_ANIMATED YES
#endif

UIInterfaceOrientation MPInterfaceOrientation(void);
UIWindow *MPKeyWindow(void);
CGFloat MPStatusBarHeight(void);
CGRect MPApplicationFrame(BOOL includeSafeAreaInsets);
CGRect MPScreenBounds(void);
CGSize MPScreenResolution(void);
CGFloat MPDeviceScaleFactor(void);
NSDictionary *MPDictionaryFromQueryString(NSString *query);
NSString *MPSHA1Digest(NSString *string);
BOOL MPViewIsVisible(UIView *view);
BOOL MPViewIntersectsParentWindowWithPercent(UIView *view, CGFloat percentVisible);
NSString *MPResourcePathForResource(NSString *resourceName);
NSArray *MPConvertStringArrayToURLArray(NSArray *strArray);

////////////////////////////////////////////////////////////////////////////////////////////////////

typedef NS_ENUM(NSUInteger, MobiInterstitialCloseButtonStyle) {
    MobiInterstitialCloseButtonStyleAlwaysVisible,
    MobiInterstitialCloseButtonStyleAlwaysHidden,
    MobiInterstitialCloseButtonStyleAdControlled,
};

typedef NS_ENUM(NSUInteger, MobiInterstitialOrientationType) {
    MobiInterstitialOrientationTypePortrait,
    MobiInterstitialOrientationTypeLandscape,
    MobiInterstitialOrientationTypeAll,
};

////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *  视频播放器状态
 *
 *  播放器只可能处于以下状态中的一种
 *
 */
typedef NS_ENUM(NSUInteger, MobiMediaPlayerStatus) {
    MobiMediaPlayerStatusInitial = 0,         // 初始状态
    MobiMediaPlayerStatusLoading = 1,         // 加载中
    MobiMediaPlayerStatusStarted = 2,         // 开始播放
    MobiMediaPlayerStatusPaused = 3,          // 用户行为导致暂停
    MobiMediaPlayerStatusStoped = 4,          // 播放停止
    MobiMediaPlayerStatusError = 5,           // 播放出错
};

UIInterfaceOrientationMask MobiInterstitialOrientationTypeToUIInterfaceOrientationMask(MobiInterstitialOrientationType type);

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface UIDevice (MobiAdditions)

- (NSString *)mobi_hardwareDeviceName;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface UIApplication (MobiAdditions)

- (BOOL)mobi_supportsOrientationMask:(UIInterfaceOrientationMask)orientationMask;
- (BOOL)mobi_doesOrientation:(UIInterfaceOrientation)orientation matchOrientationMask:(UIInterfaceOrientationMask)orientationMask;

@end
