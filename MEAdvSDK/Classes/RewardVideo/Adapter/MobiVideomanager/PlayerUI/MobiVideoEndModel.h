//
//  VideoEndModel.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/15.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MobiVideoEndModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailscribe;
@property (nonatomic, copy) NSString *bigIconUrl;
@property (nonatomic, copy) NSString *smallIconUrl;

/// playing model
@property (nonatomic, assign) NSInteger countDownTime;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appDescribe;
@property (nonatomic, copy) NSString *downloadUrl;

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *buttonStr;

@end

NS_ASSUME_NONNULL_END
