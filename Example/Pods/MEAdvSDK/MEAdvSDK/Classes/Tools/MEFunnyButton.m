//
//  MEFunnyButton.m
//  MEPedometer
//
//  Created by 刘峰 on 2020/1/2.
//  Copyright © 2020 Liufeng. All rights reserved.
//

#import "MEFunnyButton.h"
#import "MEFunnyButton.h"
#import "UIImage+Library.h"

@implementation MEFunnyButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setImage:[UIImage bundleImageNamed:@"funny_close"] forState:UIControlStateNormal];
        self.enabled = NO;
    }
    return self;
}

@end
