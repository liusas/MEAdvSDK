//
//  VideoEndView.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/15.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobiVideoEndModel.h"

@protocol MobiVideoEndViewDelegate <NSObject>

/// 关闭视频
- (void)videoCloseClick;
/// 立即下载
- (void)videoDownloadClick;
@end

@interface MobiVideoEndView : UIView

@property (nonatomic, strong) MobiVideoEndModel *model;
@property (nonatomic, weak) id<MobiVideoEndViewDelegate>delegate;

- (instancetype)init;

- (void)showViewWithModel:(MobiVideoEndModel *)model;

@end

