//
//  XFLoaderURLConnectionTask.h
//  Mobi_Vedio
//
//  Created by 李新丰 on 2020/7/10.
//  Copyright © 2020 李新丰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class MobiXFVideoRequestTask;

@protocol MobiXFloaderURLConnectionDelegate <NSObject>

- (void)didFinishLoadingWithTask:(MobiXFVideoRequestTask *)task;
- (void)didFailLoadingWithTask:(MobiXFVideoRequestTask *)task WithError:(NSInteger )errorCode;

@end

@interface MobiXFLoaderURLConnection : NSURLConnection <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) MobiXFVideoRequestTask *task;
@property (nonatomic, weak  ) id<MobiXFloaderURLConnectionDelegate> delegate;
- (NSURL *)getSchemeVideoURL:(NSURL *)url;

@end
