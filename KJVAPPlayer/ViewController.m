//
//  ViewController.m
//  KJVAPPlayer
//
//  Created by TigerHu on 2024/9/11.
//

#import "ViewController.h"
#import "UIView+VAP.h"
#import "QGVAPWrapView.h"
#import <AVFoundation/AVFoundation.h>
#import "KJVAPPlayer-Swift.h"

@interface ViewController () <HWDMP4PlayDelegate, VAPWrapViewDelegate>

@property (nonatomic, strong) UIButton *vapButton;
@property (nonatomic, strong) UIButton *vapxButton;
@property (nonatomic, strong) UIButton *vapWrapViewButton;
@property (nonatomic, strong) UIButton *vapxSwiftButton;

@property (nonatomic, strong) VAPView *vapView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAudioSession];
    
    //vap-经典效果
    _vapButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 100, CGRectGetWidth(self.view.frame), 90)];
    _vapButton.backgroundColor = [UIColor lightGrayColor];
    [_vapButton setTitle:@"电竞方案（退后台结束）" forState:UIControlStateNormal];
    [_vapButton addTarget:self action:@selector(playVap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_vapButton];
    
    //vapx-融合效果
    _vapxButton = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_vapButton.frame)+60, CGRectGetWidth(self.view.frame), 90)];
    _vapxButton.backgroundColor = [UIColor lightGrayColor];
    [_vapxButton setTitle:@"融合特效（退后台暂停/恢复）" forState:UIControlStateNormal];
    [_vapxButton addTarget:self action:@selector(playVapx) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_vapxButton];
    
    //vapx-融合效果(Swift)
    _vapxSwiftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_vapButton.frame)+360, CGRectGetWidth(self.view.frame), 90)];
    _vapxSwiftButton.backgroundColor = [UIColor lightGrayColor];
    [_vapxSwiftButton setTitle:@"融合特效Swift（点击跳转）" forState:UIControlStateNormal];
    [_vapxSwiftButton addTarget:self action:@selector(playVapxSwift) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_vapxSwiftButton];
    
    
    //使用WrapView，支持ContentMode
    _vapWrapViewButton = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_vapxButton.frame)+60, CGRectGetWidth(self.view.frame), 90)];
    _vapWrapViewButton.backgroundColor = [UIColor lightGrayColor];
    [_vapWrapViewButton setTitle:@"WrapView-ContentMode" forState:UIControlStateNormal];
    [_vapWrapViewButton addTarget:self action:@selector(playVapWithWrapView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_vapWrapViewButton];
}

- (void)setupAudioSession {
    AVAudioSession* avsession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if (![avsession setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:&error]) {
        if (error) NSLog(@"AVAudioSession setCategory failed : %ld, %s", (long)error.code, [error.localizedDescription UTF8String]);
        return;
    }
    if (![avsession setActive:YES error:&error]) {
        if (error) NSLog(@"AVAudioSession setActive failed : %ld, %s", (long)error.code, [error.localizedDescription UTF8String]);
    }
}

#pragma mark - 各种类型的播放

- (void)playVap {
    VAPView *mp4View = [[VAPView alloc] initWithFrame:CGRectMake(0, 0, 752/2, 752/2)];
    //默认使用metal渲染，使用OpenGL请打开下面这个开关
//    mp4View.hwd_renderByOpenGL = YES;
    mp4View.center = self.view.center;
    [self.view addSubview:mp4View];
    mp4View.userInteractionEnabled = YES;
    mp4View.hwd_enterBackgroundOP = HWDMP4EBOperationTypeStop;// 默认为该项，退后台时结束播放
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onImageviewTap:)];
    [mp4View addGestureRecognizer:tap];
    NSString *resPath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
    //单纯播放的接口
    //[mp4View playHWDMp4:resPath];
    //指定素材混合模式，重复播放次数，delegate的接口
    
    //注意若素材不含vapc box，则必须用调用如下接口设置enable才可播放
    [mp4View enableOldVersion:YES];
    [mp4View playHWDMP4:resPath repeatCount:-1 delegate:self];
}

//vap动画
- (void)playVapx {
    NSString *mp4Path = [[NSBundle mainBundle] pathForResource:@"vap" ofType:@"mp4"];
    VAPView *mp4View = [[VAPView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:mp4View];
    mp4View.center = self.view.center;
    mp4View.userInteractionEnabled = YES;
    mp4View.hwd_enterBackgroundOP = HWDMP4EBOperationTypePauseAndResume; // ⚠️ 建议设置该选项时对机型进行判断，屏蔽低端机
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onImageviewTap:)];
    [mp4View addGestureRecognizer:tap];
//    [mp4View setMute:YES];
    [mp4View playHWDMP4:mp4Path repeatCount:-1 delegate:self];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [mp4View pauseHWDMP4];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [mp4View resumeHWDMP4];
        });
    });
}

//vap动画Swift
- (void)playVapxSwift {
    KJShowViewController *vc = [[KJShowViewController alloc] init];
    [self.navigationController pushViewController:vc animated:NO];
}

/// 使用WrapView，支持ContentMode
- (void)playVapWithWrapView {
    static BOOL pause = NO;
    QGVAPWrapView *wrapView = [[QGVAPWrapView alloc] initWithFrame:self.view.bounds];
    wrapView.center = self.view.center;
    wrapView.contentMode = QGVAPWrapViewContentModeAspectFit;//可以设置其`contentMode`属性
    wrapView.autoDestoryAfterFinish = YES;
    [self.view addSubview:wrapView];
    NSString *resPath = [[NSBundle mainBundle] pathForResource:@"vap" ofType:@"mp4"];
//    [wrapView setMute:YES];
    [wrapView playHWDMP4:resPath repeatCount:-1 delegate:self];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doNothingonImageviewTap:)];
    //手势识别
    __weak __typeof(wrapView) weakWrapView = wrapView;
    [wrapView addVapGesture:tap callback:^(UIGestureRecognizer *gestureRecognizer, BOOL insideSource, QGVAPSourceDisplayItem *source) {
        if ((pause = !pause)) {
            [weakWrapView pauseHWDMP4];
        } else {
            [weakWrapView resumeHWDMP4];
        }
    }];
    
}

#pragma mark -  mp4 hwd delegate

#pragma mark -- 播放流程
- (void)viewDidStartPlayMP4:(VAPView *)container {
    
}

- (void)viewDidFinishPlayMP4:(NSInteger)totalFrameCount view:(UIView *)container {
    //note:在子线程被调用
}

- (void)viewDidPlayMP4AtFrame:(QGMP4AnimatedImageFrame *)frame view:(UIView *)container {
    //note:在子线程被调用
}

- (void)viewDidStopPlayMP4:(NSInteger)lastFrameIndex view:(UIView *)container {
    //note:在子线程被调用
    dispatch_async(dispatch_get_main_queue(), ^{
        [container removeFromSuperview];
    });
}

- (BOOL)shouldStartPlayMP4:(VAPView *)container config:(QGVAPConfigModel *)config {
    return YES;
}

- (void)viewDidFailPlayMP4:(NSError *)error {
    NSLog(@"%@", error.userInfo);
}

#pragma mark -- 融合特效的接口 vapx
//融合动画：delegate中实现下面两个接口，替换tag内容和下载图片

//provide the content for tags, maybe text or url string ...
- (NSString *)contentForVapTag:(NSString *)tag resource:(QGVAPSourceInfo *)info {
    
    NSDictionary *extraInfo = @{@"[sImg1]" : @"http://shp.qlogo.cn/pghead/Q3auHgzwzM6GuU0Y6q6sKHzq3MjY1aGibIzR4xrJc1VY/60",
                                @"[textAnchor]" : @"我是主播名",
                                @"[textUser]" : @"我是用户名😂😂",};
    return extraInfo[tag];
}

//provide image for url from tag content
- (void)loadVapImageWithURL:(NSString *)urlStr context:(NSDictionary *)context completion:(VAPImageCompletionBlock)completionBlock {
    
    //call completionBlock as you get the image, both sync or asyn are ok.
    //usually we'd like to make a net request
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *resPath = [[NSBundle mainBundle] pathForResource:@"qq" ofType:@"png"];
        UIImage *image = [UIImage imageNamed:resPath];
        //let's say we've got result here
        completionBlock(image, nil, urlStr);
    });
}

#pragma mark - gesture

- (void)onImageviewTap:(UIGestureRecognizer *)ges {
    
    [ges.view removeFromSuperview];
}

- (void)doNothingonImageviewTap:(UIGestureRecognizer *)ges {
    
}

#pragma mark - WrapViewDelegate

//provide the content for tags, maybe text or url string ...
- (NSString *)vapWrapview_contentForVapTag:(NSString *)tag resource:(QGVAPSourceInfo *)info {
    NSDictionary *extraInfo = @{@"[sImg1]" : @"http://shp.qlogo.cn/pghead/Q3auHgzwzM6GuU0Y6q6sKHzq3MjY1aGibIzR4xrJc1VY/60",
                                @"[textAnchor]" : @"我是主播名",
                                @"[textUser]" : @"我是用户名😂😂",};
    return extraInfo[tag];
}

//provide image for url from tag content
- (void)vapWrapView_loadVapImageWithURL:(NSString *)urlStr context:(NSDictionary *)context completion:(VAPImageCompletionBlock)completionBlock {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *resPath = [[NSBundle mainBundle] pathForResource:@"qq" ofType:@"png"];
        UIImage *image = [UIImage imageNamed:resPath];
        completionBlock(image, nil, urlStr);
    });
}

@end
