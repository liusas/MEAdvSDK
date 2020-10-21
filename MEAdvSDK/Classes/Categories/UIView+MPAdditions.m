//
//  UIView+MPAdditions.m
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "UIView+MPAdditions.h"

@implementation UIView (Helper)

- (CGFloat)mp_x
{
    return self.frame.origin.x;
}

- (CGFloat)mp_y
{
    return self.frame.origin.y;
}

- (CGFloat)mp_width
{
    return self.frame.size.width;
}

- (CGFloat)mp_height
{
    return self.frame.size.height;
}

- (CGFloat)mb_maxX {
    return CGRectGetMaxX(self.frame);
}

- (CGFloat)mb_maxY {
    return CGRectGetMaxY(self.frame);
}

- (CGFloat)mb_centerX {
    return self.center.x;
}

- (CGFloat)mb_centerY {
    return self.center.y;
}

- (void)setMp_x:(CGFloat)mp_x
{
    [self setX:mp_x andY:self.frame.origin.y];
}

- (void)setMp_y:(CGFloat)mp_y
{
    [self setX:self.frame.origin.x andY:mp_y];
}

- (void)setX:(CGFloat)x andY:(CGFloat)y
{
    CGRect f = self.frame;
    self.frame = CGRectMake(x, y, f.size.width, f.size.height);
}


- (void)setMp_width:(CGFloat)mp_width
{
    CGRect frame = self.frame;
    frame.size.width = mp_width;
    self.frame = frame;
}

- (void)setMp_height:(CGFloat)mp_height
{
    CGRect frame = self.frame;
    frame.size.height = mp_height;
    self.frame = frame;
}

- (void)setMp_maxX:(CGFloat)maxX {
    // 1.必须通过结构体赋值.直接赋值,涉及到计算时会出错.
    // 2.必须将x,y,当做已知条件;宽,高当做未知条件.涉及到计算时,才能正确计算出在父控件中的位置.
    // ❌错误方法 frame.origin.x = maxX - frame.size.width;
    // 错误原因:可能此时的宽度还没有值,所以计算出来的值是错误的.
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, maxX - self.frame.origin.x, self.frame.size.height);
}

- (void)setMp_maxY:(CGFloat)maxY {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, maxY - self.frame.origin.y);
}

- (void)setMp_centerX:(CGFloat)centerX {
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

- (void)setMp_centerY:(CGFloat)centerY {
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (UIView *)mp_snapshotView
{
    CGRect rect = self.bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.window.screen.scale);
    UIView *snapshotView;
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        snapshotView = [self snapshotViewAfterScreenUpdates:NO];
    } else {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [self.layer renderInContext:ctx];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        snapshotView = [[UIImageView alloc] initWithImage:image];
    }
    UIGraphicsEndImageContext();
    return snapshotView;
}

- (UIImage *)mp_snapshot:(BOOL)usePresentationLayer
{
    CGRect rect = self.bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.window.screen.scale);
    if (!usePresentationLayer && [self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self drawViewHierarchyInRect:rect afterScreenUpdates:NO];
    } else {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        if (usePresentationLayer) {
            [self.layer.presentationLayer renderInContext:ctx];
        } else {
            [self.layer renderInContext:ctx];
        }
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@implementation UIView (MPSafeArea)

- (NSLayoutXAxisAnchor *)mp_safeLeadingAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.leadingAnchor;
    } else {
        return self.leadingAnchor;
    }
}

- (NSLayoutXAxisAnchor *)mp_safeTrailingAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.trailingAnchor;
    } else {
        return self.trailingAnchor;
    }
}

- (NSLayoutXAxisAnchor *)mp_safeLeftAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.leftAnchor;
    } else {
        return self.leftAnchor;
    }
}

- (NSLayoutXAxisAnchor *)mp_safeRightAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.rightAnchor;
    } else {
        return self.rightAnchor;
    }
}

- (NSLayoutYAxisAnchor *)mp_safeTopAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.topAnchor;
    } else {
        return self.topAnchor;
    }
}

- (NSLayoutYAxisAnchor *)mp_safeBottomAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.bottomAnchor;
    } else {
        return self.bottomAnchor;
    }
}

- (NSLayoutDimension *)mp_safeWidthAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.widthAnchor;
    } else {
        return self.widthAnchor;
    }
}

- (NSLayoutDimension *)mp_safeHeightAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.heightAnchor;
    } else {
        return self.heightAnchor;
    }
}

- (NSLayoutXAxisAnchor *)mp_safeCenterXAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.centerXAnchor;
    } else {
        return self.centerXAnchor;
    }
}

- (NSLayoutYAxisAnchor *)mp_safeCenterYAnchor {
    if (@available(iOS 11, *)) {
        return self.safeAreaLayoutGuide.centerYAnchor;
    } else {
        return self.centerYAnchor;
    }
}

@end
