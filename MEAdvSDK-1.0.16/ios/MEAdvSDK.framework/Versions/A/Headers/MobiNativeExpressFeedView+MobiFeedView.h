//
//  MobiNativeExpressFeedView+MobiFeedView.h
//  MobiPubSDK
//
//  Created by 卢镝 on 2020/7/31.
//

#import "MobiNativeExpressFeedView.h"
@class MobiAdNativeBaseClass;

@interface MobiNativeExpressFeedView (MobiFeedView)

/**
构造方法

feedViewSize 传入信息流的size，由用户设置传入
nativeBase 广告的详细信息
*/
- (instancetype)initWithNativeExpressFeedViewSize:(CGSize)feedViewSize delegate:(id)delegate;

/**
填充信息流广告

nativeBase 广告的详细信息
*/
- (void)refreshUIWithNativeBaseClass:(MobiAdNativeBaseClass *)nativeBase;

@end

