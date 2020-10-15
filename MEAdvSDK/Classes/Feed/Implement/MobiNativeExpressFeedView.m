//
//  MobiNativeExpressFeedView.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/17.
//

#import "MobiNativeExpressFeedView.h"
#import "MobiAdNativeBaseClass.h"
#import "MobiLaunchAdCache.h"
#import "MPAdDestinationDisplayAgent.h"// 展示点击广告后的效果的代理类

//水平方向左右边距
static CGFloat const margin = 15;
//水平方向间距（图片&图片）
static CGFloat const imgEdge = 5;
//水平方向间距（文字&图片）
static CGFloat const titleImgEdge = 10;
//上下左右间距
static UIEdgeInsets const padding = {10, 0, 10, 0};

@interface MobiNativeExpressFeedView () <MPAdDestinationDisplayAgentDelegate>

///信息流广告标题
@property (nonatomic, strong, nullable) UILabel *adTitleLabel;
///信息流广告单张图片
@property (nonatomic, strong, nullable) UIImageView *adImg;

///信息流广告三张图片
@property (nonatomic, strong, nullable) UIImageView *img1;
@property (nonatomic, strong, nullable) UIImageView *img2;
@property (nonatomic, strong, nullable) UIImageView *img3;

///数据模型
@property (nonatomic, strong) MobiAdNativeBaseClass * nativeBase;
///展示点击广告后的效果的代理类
@property (nonatomic, strong) id<MPAdDestinationDisplayAgent> destinationDisplayAgent;
// 手指按下的点
@property (nonatomic, assign) CGPoint downPoint;
// 手指抬起的点
@property (nonatomic, assign) CGPoint upPoint;

@end

@implementation MobiNativeExpressFeedView

- (instancetype)initWithNativeExpressFeedViewSize:(CGSize)feedViewSize delegate:(id)delegate {
    
    if (self = [super init]) {
        self.backgroundColor = [UIColor whiteColor];
        self.frame = CGRectMake(0, 0, feedViewSize.width, feedViewSize.height);
        _delegate = delegate;
        //初始化点击广告后的效果的代理类
        self.destinationDisplayAgent = [MPAdDestinationDisplayAgent agentWithDelegate:self];
    
        [self setupUI];
    }
    return self;
}

//MARK: 公共UI部分初始化及一些属性设置
- (void)setupUI {
    
    self.adImg = [[UIImageView alloc] init];
    self.adImg.userInteractionEnabled = YES;
    [self addSubview:self.adImg];
    
    self.adTitleLabel = [UILabel new];
    self.adTitleLabel.numberOfLines = 0;
    self.adTitleLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.adTitleLabel];
}

//MARK: 填充信息流广告
- (void)refreshUIWithNativeBaseClass:(MobiAdNativeBaseClass *)nativeBase {
    
    self.nativeBase = nativeBase;
    
    if (nativeBase.style == 10201) {//信息流:单图480*360,一级样式id:102,二级样式id:10201,素材描述主图：480*360、标题、描述
        [self nativeExpressFeedViewTopTitleBottomImg:nativeBase];
    }else if (nativeBase.style == 10211) {//信息流:三图480*360,一级样式id:102,二级样式id:10211,主图：480*360 X 3、标题、描述
        [self nativeExpressFeedViewTopTitleBottomThreeImgs:nativeBase];
    }
}

//MARK: 信息流上文下图
- (void)nativeExpressFeedViewTopTitleBottomImg:(MobiAdNativeBaseClass *)nativeBase {
    
    MobiAdNativeImg *nativeImg = nativeBase.img[0];
    if (![MobiLaunchAdCache checkImageInCacheWithURL:[NSURL URLWithString:nativeImg.url]]) {
        self.frame = CGRectZero;
        if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderFailForFeedView:)]) {
            [self.delegate nativeExpressAdViewRenderFailForFeedView:self];
        }
        return;
    }
    
    CGFloat width = self.frame.size.width;
    CGFloat titleImgWidth = (width - 2 * margin);

    CGSize titleSize = [self titleAttributeText:nativeBase.title rectSize:CGSizeMake(titleImgWidth, 0)];

    CGFloat imgHeight = titleImgWidth * ([nativeImg.h floatValue] / [nativeImg.w floatValue]);
    self.adImg.frame = CGRectMake(margin, padding.top + CGRectGetMaxY(self.adTitleLabel.frame), titleImgWidth, imgHeight);
    self.adImg.image = [MobiLaunchAdCache getCacheImageWithURL:[NSURL URLWithString:nativeImg.url]];

    self.frame = CGRectMake(0, 0, width, 2 * padding.top + padding.bottom + titleSize.height + imgHeight);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderSuccessForFeedView:)]) {
        [self.delegate nativeExpressAdViewRenderSuccessForFeedView:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewExposureForFeedView:)]) {
        [self.delegate nativeExpressAdViewExposureForFeedView:self];
    }
}

//MARK: 信息流上方文字，下方三张图片
- (void)nativeExpressFeedViewTopTitleBottomThreeImgs:(MobiAdNativeBaseClass *)nativeBase {
    
    [nativeBase.img enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MobiAdNativeImg *nativeImg = (MobiAdNativeImg *)obj;
        if (![MobiLaunchAdCache checkImageInCacheWithURL:[NSURL URLWithString:nativeImg.url]]) {
            self.frame = CGRectZero;
            if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderFailForFeedView:)]) {
                [self.delegate nativeExpressAdViewRenderFailForFeedView:self];
            }
            return;
        }
    }];
    
    CGFloat width = self.frame.size.width;
    CGFloat titleWidth = (width - 2 * margin);
    
    CGSize titleSize = [self titleAttributeText:nativeBase.title rectSize:CGSizeMake(titleWidth, 0)];

    MobiAdNativeImg *nativeImg1 = nativeBase.img[0];
    MobiAdNativeImg *nativeImg2 = nativeBase.img[1];
    MobiAdNativeImg *nativeImg3 = nativeBase.img[2];
    CGFloat imgWidth = (width - 2 * margin - 2 * imgEdge)/3.f;
    CGFloat imgHeight = imgWidth * ([nativeImg1.h floatValue] / [nativeImg1.w floatValue]);
    self.img1 = [[UIImageView alloc] initWithFrame:CGRectMake(margin, CGRectGetMaxY(self.adTitleLabel.frame) + padding.top, imgWidth, imgHeight)];
    self.img1.image = [MobiLaunchAdCache getCacheImageWithURL:[NSURL URLWithString:nativeImg1.url]];
    [self addSubview:self.img1];

    self.img2 = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.img1.frame) + imgEdge, CGRectGetMinY(self.img1.frame), imgWidth, imgHeight)];
    self.img2.image = [MobiLaunchAdCache getCacheImageWithURL:[NSURL URLWithString:nativeImg2.url]];
    [self addSubview:self.img2];

    self.img3 = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.img2.frame) + imgEdge, CGRectGetMinY(self.img1.frame), imgWidth, imgHeight)];
    self.img3.image = [MobiLaunchAdCache getCacheImageWithURL:[NSURL URLWithString:nativeImg3.url]];
    [self addSubview:self.img3];

    self.frame = CGRectMake(0, 0, width, 2 * padding.top + padding.bottom + titleSize.height + imgHeight);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderSuccessForFeedView:)]) {
        [self.delegate nativeExpressAdViewRenderSuccessForFeedView:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewExposureForFeedView:)]) {
        [self.delegate nativeExpressAdViewExposureForFeedView:self];
    }
}

//MARK: 信息流仅有一张图片
- (void)nativeExpressFeedViewOnlyImg:(MobiAdNativeBaseClass *)nativeBase {
    
    CGFloat width = self.frame.size.width;
    
    CGFloat imgWidth = (width - 2 * margin);
    CGFloat imgHeight = imgWidth * (400 / 200);
    self.adImg.frame = CGRectMake(margin, padding.top, imgWidth, imgHeight);
    self.adImg.backgroundColor = [UIColor greenColor];
    
    self.frame = CGRectMake(0, 0, width, padding.top + padding.bottom + imgHeight);
}

//MARK: 信息流左图右文
- (void)nativeExpressFeedViewLeftTitleRightImg:(MobiAdNativeBaseClass *)nativeBase {
    
    CGFloat width = self.frame.size.width;
    
    CGFloat imgWidth = width/3.f;
    CGFloat imgHeight = imgWidth * (400 / 200);
    self.adImg.frame = CGRectMake(margin, padding.top, imgWidth, imgHeight);
    self.adImg.backgroundColor = [UIColor greenColor];
    
//
//    CGFloat titleWidth = (width - 2 * margin - imgWidth - titleImgEdge);
//    NSAttributedString *attributedText = [self titleAttributeText:model.title];
//    CGSize titleSize = [attributedText boundingRectWithSize:CGSizeMake(titleWidth, 0) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:0].size;
//    self.adTitleLabel.frame = CGRectMake(CGRectGetMaxX(self.adImg.frame) + titleImgEdge, CGRectGetMinY(self.adImg.frame), titleWidth, titleSize.height);
//    self.adTitleLabel.attributedText = attributedText;
//
//    if (titleSize.height >= imgHeight) {
//        self.frame = CGRectMake(0, 0, width, padding.top + padding.bottom + titleSize.height);
//    }else{
//        self.frame = CGRectMake(0, 0, width, padding.top + padding.bottom + imgHeight);
//    }
}

// MARK: - <MPAdDestinationDisplayAgentDelegate>

- (UIViewController *)viewControllerForPresentingModalView
{
    if (self.controller) {
        return self.controller;
    }
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

- (void)displayAgentWillPresentModal
{
    [self.delegate nativeExpressAdViewWillPresentScreenForFeedView:self];
}

- (void)displayAgentWillLeaveApplication
{

}

- (void)displayAgentDidDismissModal
{
    [self.delegate nativeExpressAdViewWillDissmissScreenForFeedView:self];
    [self.delegate nativeExpressAdViewDidDissmissScreenForFeedView:self];
}


//MARK: 上报数据

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.downPoint = [touch locationInView:self];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.upPoint = [touch locationInView:self];
    
    [self clickAndPoint:self.downPoint upPoint:self.upPoint];
}

///点击页面跳转到广告详情页面
-(void)clickAndPoint:(CGPoint)downPoint upPoint:(CGPoint)upPoint {
    
    if (!self.nativeBase) {
        return;
    }
    
    MobiFeedAdReportModel *model = [MobiFeedAdReportModel new];
    model.clickDownPoint = downPoint;
    model.clickUpPoint = upPoint;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewClickedForFeedView:reportModel:)]) {
        [self.delegate nativeExpressAdViewClickedForFeedView:self reportModel:model];
    }
    
    NSMutableDictionary *resolveDic = [NSMutableDictionary dictionary];
    resolveDic[@"ctype"] = @(self.nativeBase.ctype);
    resolveDic[@"curl"] = self.nativeBase.curl;
    resolveDic[@"durl"] = self.nativeBase.dlinkDurl;
    resolveDic[@"wurl"] = self.nativeBase.dlinkWurl;
    resolveDic[@"dlink_track"] = self.nativeBase.dlinkTrack;
    
    [self.destinationDisplayAgent displayDestinationForDict:resolveDic downPoint:downPoint upPoint:upPoint];
}


//MARK: private

///设置adTitleLabel文字，并返回文本高度
- (CGSize)titleAttributeText:(NSString *)text rectSize:(CGSize)size {
    if (text.length == 0) {
        return CGSizeZero;
    }
    
    UIFont *font = [UIFont systemFontOfSize:17.f];
    //获取文字正常的高度，以便后续判定是否设置行间距，一行的时候如果设置了行间距会有问题
    CGSize textSize = [self getTextSizeWithText:text Font:font constrainedToSize:size];
    
    NSMutableDictionary *attribute = @{}.mutableCopy;
    NSMutableParagraphStyle * titleStrStyle = [[NSMutableParagraphStyle alloc] init];
    if (textSize.height > 2 * font.pointSize) {
        titleStrStyle.lineSpacing = 5;
    }
    titleStrStyle.alignment = NSTextAlignmentJustified;
    attribute[NSFontAttributeName] = font;
    attribute[NSParagraphStyleAttributeName] = titleStrStyle;
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attribute];
    CGSize titleSize = [attributedText boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:0].size;
    self.adTitleLabel.frame = CGRectMake(margin, padding.top , size.width, titleSize.height);
    self.adTitleLabel.attributedText = attributedText;
    
    return titleSize;
}

//计算文字的高度
- (CGSize)getTextSizeWithText:(NSString *)text Font:(UIFont *)font constrainedToSize:(CGSize)size{
    CGSize resultSize = CGSizeZero;
    if (text.length <= 0) {
        return resultSize;
    }
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    resultSize = [text boundingRectWithSize:CGSizeMake(floor(size.width), floor(size.height))//用相对小的 width 去计算 height / 小 heigth 算 width
                                    options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin)
                                 attributes:@{NSFontAttributeName: font,
                                              NSParagraphStyleAttributeName: style}
                                    context:nil].size;
    resultSize = CGSizeMake(floor(resultSize.width + 1), floor(resultSize.height + 1));//上面用的小 width（height） 来计算了，这里要 +1
    return resultSize;
}


@end

@implementation MobiFeedAdReportModel
@end
