//
//  MobiLaunchAdImageView.m
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "MobiLaunchAdImageView.h"

@interface MobiLaunchAdImageView ()

// 手指按下的点
@property (nonatomic, assign) CGPoint downPoint;
// 手指抬起的点
@property (nonatomic, assign) CGPoint upPoint;

@end

@implementation MobiLaunchAdImageView

- (id)init{
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.frame = [UIScreen mainScreen].bounds;
        self.layer.masksToBounds = YES;
//        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
//        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

//- (void)tap:(UIGestureRecognizer *)gestureRecognizer{
//    CGPoint point = [gestureRecognizer locationInView:self];
//    if(self.click) self.click(point);
//}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.downPoint = [touch locationInView:self];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.upPoint = [touch locationInView:self];
    
    if (self.click) {
        self.click(self.downPoint, self.upPoint);
    }
}

- (void)mobi_setImageWithURL:(nonnull NSURL *)url{
    [self mobi_setImageWithURL:url placeholderImage:nil];
}

- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder{
    [self mobi_setImageWithURL:url placeholderImage:placeholder options:MobiLaunchAdImageDefault];
}

- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(MobiLaunchAdImageOptions)options{
    [self mobi_setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)mobi_setImageWithURL:(nonnull NSURL *)url completed:(nullable MobiExternalCompletionBlock)completedBlock {
    
    [self mobi_setImageWithURL:url placeholderImage:nil completed:completedBlock];
}

- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable MobiExternalCompletionBlock)completedBlock{
    [self mobi_setImageWithURL:url placeholderImage:placeholder options:MobiLaunchAdImageDefault completed:completedBlock];
}

- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(MobiLaunchAdImageOptions)options completed:(nullable MobiExternalCompletionBlock)completedBlock{
    [self mobi_setImageWithURL:url placeholderImage:placeholder GIFImageCycleOnce:NO options:options GIFImageCycleOnceFinish:nil completed:completedBlock ];
}

- (void)mobi_setImageWithURL:(nonnull NSURL *)url placeholderImage:(nullable UIImage *)placeholder GIFImageCycleOnce:(BOOL)GIFImageCycleOnce options:(MobiLaunchAdImageOptions)options GIFImageCycleOnceFinish:(void(^_Nullable)(void))cycleOnceFinishBlock completed:(nullable MobiExternalCompletionBlock)completedBlock {
    if(placeholder) self.image = placeholder;
    if(!url) return;
    MobiWeakSelf
    [[MobiLaunchAdImageManager sharedManager] loadImageWithURL:url options:options progress:nil completed:^(UIImage * _Nullable image,  NSData *_Nullable imageData, NSError * _Nullable error, NSURL * _Nullable imageURL) {
        if(!error){
            if(MobiISGIFTypeWithData(imageData)){
                weakSelf.image = nil;
                weakSelf.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
                weakSelf.loopCompletionBlock = ^(NSUInteger loopCountRemaining) {
                    if(GIFImageCycleOnce){
                       [weakSelf stopAnimating];
                        MobiLaunchAdLog(@"GIF不循环,播放完成");
                        if(cycleOnceFinishBlock) cycleOnceFinishBlock();
                    }
                };
            }else{
                weakSelf.image = image;
                weakSelf.animatedImage = nil;
            }
        }
        if(completedBlock) completedBlock(image,imageData,error,imageURL);
    }];
}

@end
