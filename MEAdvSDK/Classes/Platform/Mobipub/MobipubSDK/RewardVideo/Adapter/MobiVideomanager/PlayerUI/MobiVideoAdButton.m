//
//  MobiLaunchAdButton.m
//  MobiSplashDemo
//
//  Created by 卢镝 on 2020/6/29.
//  Copyright © 2020 卢镝. All rights reserved.
//

#import "MobiVideoAdButton.h"
#import "MobiVideoAdConst.h"
#import "MobiVideoAppConfig.h"

/** Progress颜色 */
#define RoundProgressColor  [UIColor whiteColor]
/** 背景色 */
#define BackgroundColor [UIColor colorWithRed:0 green:0 blue:0 alpha:0.34]
/** 字体颜色 */
#define FontColor  [UIColor whiteColor]

#define SkipTitle @"跳过"
/** 倒计时单位 */
#define DurationUnit @"S"

@interface MobiVideoAdButton ()

@property(nonatomic,assign)MobiSkipType skipType;
@property(nonatomic,assign)CGFloat leftRightSpace;
@property(nonatomic,assign)CGFloat topBottomSpace;
@property(nonatomic,strong)UILabel *timeLab;
@property (nonatomic,strong) CAShapeLayer *roundLayer;
@property(nonatomic,copy)dispatch_source_t roundTimer;

@end

@implementation MobiVideoAdButton

- (instancetype)initWithSkipType:(MobiSkipType)skipType{
    self = [super init];
    if (self) {
        
        _skipType = skipType;
        self.enabled = NO;
        CGFloat y = Mobi_FULLSCREEN ? 44 : 20;
        //self.frame = CGRectMake(Mobi_ScreenW - 80, y, 70, 35);//方形
        self.frame = CGRectMake(Mobi_ScreenW - kCurrentWidth(48), kCurrentWidth(5)+iPhoneStatusBarAndNavigationBarHeight, kCurrentWidth(31), kCurrentWidth(31));
        switch (skipType) {
            case MobiSkipTypeRoundTime:
            case MobiSkipTypeRoundText:
            case MobiSkipTypeRoundProgressTime:
            case MobiSkipTypeRoundProgressText:{//环形
                //self.frame = CGRectMake(Mobi_ScreenW - 55, y, 42, 42);
                self.frame = CGRectMake(Mobi_ScreenW - kCurrentWidth(48), kCurrentWidth(5)+iPhoneStatusBarAndNavigationBarHeight, kCurrentWidth(31), kCurrentWidth(31));
            }
                break;
            default:
                break;
        }
        
        switch (skipType) {
            case MobiSkipTypeNone:{
                self.hidden = YES;
            }
                break;
            case MobiSkipTypeTime:{
                [self addSubview:self.timeLab];
                self.leftRightSpace = 5;
                self.topBottomSpace = 2.5;
            }
                break;
            case MobiSkipTypeText:{
                [self addSubview:self.timeLab];
                self.leftRightSpace = 5;
                self.topBottomSpace = 2.5;
            }
                break;
            case MobiSkipTypeTimeText:{
                [self addSubview:self.timeLab];
                self.leftRightSpace = 5;
                self.topBottomSpace = 2.5;
            }
                break;
            case MobiSkipTypeRoundTime:{
                [self addSubview:self.timeLab];
            }
                break;
            case MobiSkipTypeRoundText:{
                [self addSubview:self.timeLab];
            }
                break;
            case MobiSkipTypeRoundProgressTime:{
                [self addSubview:self.timeLab];
                [self.timeLab.layer addSublayer:self.roundLayer];
            }
                break;
            case MobiSkipTypeRoundProgressText:{
                [self addSubview:self.timeLab];
                [self.timeLab.layer addSublayer:self.roundLayer];
            }
                break;
            default:
                break;
        }
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(Mobi_ScreenW - kCurrentWidth(48), kCurrentWidth(5)+iPhoneStatusBarHeight, kCurrentWidth(31), kCurrentWidth(31));
        [self addSubview:self.timeLab];
        //[self.timeLab.layer addSublayer:self.roundLayer];
        self.enabled = NO;
    }
    return self;
}

-(UILabel *)timeLab{
    if(_timeLab ==  nil){
        _timeLab = [[UILabel alloc] initWithFrame:self.bounds];
        _timeLab.textColor = FontColor;
        _timeLab.backgroundColor = BackgroundColor;
        _timeLab.layer.masksToBounds = YES;
        _timeLab.textAlignment = NSTextAlignmentCenter;
        _timeLab.font = [UIFont fontWithName:RegularFontName size:kCurrentWidth(13)];
        [self cornerRadiusWithView:_timeLab];
    }
    return _timeLab;
}

-(CAShapeLayer *)roundLayer{
    if(_roundLayer==nil){
        _roundLayer = [CAShapeLayer layer];
        _roundLayer.fillColor = BackgroundColor.CGColor;
        _roundLayer.strokeColor = RoundProgressColor.CGColor;
        _roundLayer.lineCap = kCALineCapRound;
        _roundLayer.lineJoin = kCALineJoinRound;
        _roundLayer.lineWidth = 2;
        _roundLayer.frame = self.bounds;
        _roundLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.timeLab.bounds.size.width/2.0, self.timeLab.bounds.size.width/2.0) radius:self.timeLab.bounds.size.width/2.0-1.0 startAngle:-0.5*M_PI endAngle:1.5*M_PI clockwise:YES].CGPath;
        _roundLayer.strokeStart = 0;
    }
    return _roundLayer;
}

- (void)setTitleWithSkipType:(MobiSkipType)skipType duration:(NSInteger)duration{
    _skipType = skipType;
    switch (skipType) {
        case MobiSkipTypeNone:{
            self.hidden = YES;
        }
            break;
        case MobiSkipTypeTime:{
            self.hidden = NO;
            self.timeLab.text = [NSString stringWithFormat:@"%ld %@",duration,DurationUnit];
        }
            break;
        case MobiSkipTypeText:{
            self.hidden = NO;
            self.timeLab.text = SkipTitle;
        }
            break;
        case MobiSkipTypeTimeText:{
            self.hidden = NO;
            self.timeLab.text = [NSString stringWithFormat:@"%ld %@",duration,SkipTitle];
        }
            break;
        case MobiSkipTypeRoundTime:{
            self.hidden = NO;
            self.timeLab.text = [NSString stringWithFormat:@"%ld %@",duration,DurationUnit];
        }
            break;
        case MobiSkipTypeRoundText:{
            self.hidden = NO;
            self.timeLab.text = SkipTitle;
        }
            break;
        case MobiSkipTypeRoundProgressTime:{
            self.hidden = NO;
            self.timeLab.text = [NSString stringWithFormat:@"%ld %@",duration,DurationUnit];
        }
            break;
        case MobiSkipTypeRoundProgressText:{
            self.hidden = NO;
            self.timeLab.text = SkipTitle;
        }
            break;
        default:
            break;
    }
}

-(void)startRoundDispathTimerWithDuration:(CGFloat )duration{
    NSTimeInterval period = 0.05;
    __block CGFloat roundDuration = duration;
    _roundTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(_roundTimer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_roundTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if(roundDuration<=0){
                self.roundLayer.strokeStart = 1;
                DISPATCH_SOURCE_CANCEL_SAFE(self.roundTimer);
            }
            self.roundLayer.strokeStart += 1/(duration/period);
            roundDuration -= period;
        });
    });
    dispatch_resume(_roundTimer);
    
    [self startCountDown:duration];
}

-(void)startCountDown:(int)maxTime{
    __block int time = 0;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //如果有需要可以将定时器保存为全局变量
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        if (time >= maxTime) {  //时间到了
            //清空计数
            time = 0;
            //时间到了关闭定时器
            dispatch_source_cancel(timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                //在这里执行你要的操作
                if (self.skipType == MobiSkipTypeRoundProgressText) {//跳过
                    self.timeLab.text = @"跳过";
                    self.enabled = YES;
                } else {
                    self.timeLab.text = @"0";
                    self.enabled = NO;
                }
                
            });
        }else{
            time++;
            dispatch_async(dispatch_get_main_queue(), ^{
                //在这里执行你要的操作
                self.timeLab.text = [NSString stringWithFormat:@"%d",(maxTime - time)];
            });
        }
    });
    
    dispatch_resume(timer);
}

-(void)setLeftRightSpace:(CGFloat)leftRightSpace{
    _leftRightSpace = leftRightSpace;
    CGRect frame = self.timeLab.frame;
    CGFloat width = frame.size.width;
    if(leftRightSpace<=0 || leftRightSpace*2>= width) return;
    frame = CGRectMake(leftRightSpace, frame.origin.y, width-2*leftRightSpace, frame.size.height);
    self.timeLab.frame = frame;
    [self cornerRadiusWithView:self.timeLab];
}

-(void)setTopBottomSpace:(CGFloat)topBottomSpace{
    _topBottomSpace = topBottomSpace;
    CGRect frame = self.timeLab.frame;
    CGFloat height = frame.size.height;
    if(topBottomSpace<=0 || topBottomSpace*2>= height) return;
    frame = CGRectMake(frame.origin.x, topBottomSpace, frame.size.width, height-2*topBottomSpace);
    self.timeLab.frame = frame;
    [self cornerRadiusWithView:self.timeLab];
}

-(void)cornerRadiusWithView:(UIView *)view{
    CGFloat min = view.frame.size.height;
    if(view.frame.size.height > view.frame.size.width) {
        min = view.frame.size.width;
    }
    view.layer.cornerRadius = min/2.0;
    view.layer.masksToBounds = YES;
}

@end
