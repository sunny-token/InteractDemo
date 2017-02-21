//
//  InterRactViewController.m
//  SF
//
//  Created by admin on 2017/1/13.
//  Copyright © 2017年 Focus Technology Co., Ltd. All rights reserved.
//

#import "InterRactViewController.h"

#define INTERACTLEFTMARGIN 12//左侧间距
#define INTERACTHEIGHT (SCREEN_HEIGHT - 82)//展开的高度
#define INTERACTFLODHEIGHT 120 //折叠起来的高度
#define VERT_SWIPE_DRAG_MAX    30    //垂直方向最大偏移量
#define INTERACT_CENTER_UNFOLD    (INTERACTHEIGHT/2 - 10)    //展开的中心位置y, -10为了防止 top 边缘被拉出来
#define INTERACT_CENTER_CHANGE_BG    0    //开始变化的中心点

static BOOL isBlinking = NO;
static BOOL isMoving = NO;

typedef NS_ENUM(NSInteger ,InteractViewStatus){
    InteractViewStatusShow = 0,
    InteractViewStatusFlod,
    InteractViewStatusClose,
};

@interface InterRactViewController ()<CAAnimationDelegate> {
    dispatch_semaphore_t _lock;
}
@property (nonatomic, assign) CGPoint startTouchPosition;
@property (nonatomic, assign) CGPoint startViewPosition;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) InteractViewStatus InteractStatus;
@property (nonatomic, assign) CGPoint originalFrame;
@property (nonatomic, strong) UIViewController *contentVC;//保存上一个vc 的内容
@property (nonatomic, strong) UIView *contentView;//折叠起来后展现的 view
@property (nonatomic, strong) UIButton *againBtn;//折叠起来后展现的 view的 重新作答按钮
@property (nonatomic, strong) UILabel *contentTitleLabel;//展开后中间的 view
@property (nonatomic, strong) UIView *contentTitleFoldView;//折叠起来后中间的 view
@property (nonatomic, strong) UIButton *iconDirectionBtn;//点击切换事件
@property (nonatomic, assign) BOOL isRestart;//区别重复点击和重新作答
@property (nonatomic, strong) UIImage *imageBgFold;//折叠后的背景图
@property (nonatomic, assign) BOOL canMoved;//是否点在可滑动区域

@end

@implementation InterRactViewController

#pragma mark - life cycle
- (instancetype)init {
    if (self = [super init]) {
        _tabBarWidth = 0;
        _InteractStatus = InteractViewStatusClose;
        _isRestart = NO;
        _canMoved = YES;
        _lock = dispatch_semaphore_create(1);
    }
    return  self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Do any additional setup after loading the view.
    CGFloat width = SCREEN_WIDTH - self.tabBarWidth - (INTERACTLEFTMARGIN * 2);
    CGFloat height = INTERACTHEIGHT;
    self.view.frame = CGRectMake(self.tabBarWidth + INTERACTLEFTMARGIN, - height, width, height);
    
    _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _imageView.image = [UIImage imageNamed:@"tool-bg"];
    [self.view addSubview:_imageView];
    
    _imageBgFold = [UIImage imageNamed:@"tool-bg-s"];
    UIEdgeInsets edge = UIEdgeInsetsMake(10, 0, 50,0);
    _imageBgFold = [_imageBgFold resizableImageWithCapInsets:edge resizingMode:UIImageResizingModeStretch];
    
    self.originalFrame = CGPointMake(self.view.center.x, INTERACT_CENTER_UNFOLD);
    [self registerObserver];
    [self setUpContentTitleView];
    [self.view addSubview:self.iconDirectionBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - public function
- (void)setInterRactContentViewController:(UIViewController *)contentViewController {
    if ([NSStringFromClass([contentViewController class]) isEqualToString:NSStringFromClass([self.contentVC class])] && !self.isRestart) {
        return;
    }
    NSLog(@"setInterRactContentViewController lock begin");
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSLog(@"setInterRactContentViewController lock after");

    //移除上一个 content
    [self removeInterRactContentViewController];
    contentViewController.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 44);
    [self addChildViewController:contentViewController];
    [contentViewController didMoveToParentViewController:self];
    [self.view addSubview:contentViewController.view];
    self.contentVC = contentViewController;
    [self.view bringSubviewToFront:self.contentView];
    self.isRestart = NO;
    [self setContentViewPositionAndTitleViewHidenStatus];
    NSLog(@"setInterRactContentViewController single begin");
    dispatch_semaphore_signal(_lock);
    NSLog(@"setInterRactContentViewController single after");
}

- (void)setContentTitleFoldViewForRunTime:(UIView *)contentFoldView
                                    title:(NSString *)title
                                againText:(NSString *)againStr{
    //可以随时调用
    //设置折叠起来后的 title view
    [self.contentTitleFoldView removeFromSuperview];
    self.contentTitleFoldView = contentFoldView;
    [self.contentView addSubview:self.contentTitleFoldView];
    
    [self setContentViewPositionAndTitleViewHidenStatus];
    self.contentTitleLabel.text = title;
    if (againStr && ![againStr isEqualToString:@""]) {
        [self.againBtn setTitle:againStr forState:UIControlStateNormal];
        self.againBtn.hidden = NO;
    }else {
        self.againBtn.hidden = YES;
    }
}

- (void)removeInterRactContentViewController {
    if (self.contentVC) {
        [self.contentVC willMoveToParentViewController:nil];
        [self.contentVC removeFromParentViewController];
        [self.contentVC.view removeFromSuperview];
        self.contentVC = nil;
    }
}

// 收起窗口
- (void)closeInteractView {
    [self animationToShowAndHiden:NO block:^{
    }];
}

// 展开窗口
- (void)showInteractView{
    [self resetDataWhenClose];
    [self animationToShowAndHiden:YES block:^{
    }];
}

- (UIViewController *)getInteractContentVc {
    return self.contentVC;
}

- (void)animateWhenClickBgView {
    if (self.InteractStatus != InteractViewStatusFlod) {
        return;
    }
    isBlinking = YES;
    UIImage *toImage = [UIImage imageNamed:@"tool-bg-r"];
    UIEdgeInsets edge = UIEdgeInsetsMake(10, 0, 10,0);
    toImage = [toImage resizableImageWithCapInsets:edge resizingMode:UIImageResizingModeStretch];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"contents"];
    animation.toValue = (__bridge id _Nullable)(toImage.CGImage);
    animation.fromValue = (__bridge id _Nullable)(self.imageBgFold.CGImage);
    animation.duration = 0.3f;
    animation.autoreverses = YES;
    animation.repeatCount = 3;
    animation.delegate = self;
    
    [self.imageView.layer addAnimation:animation forKey:@"contentsAnimationKey"];
}

#pragma mark - private function
//处理小幅度滑动
- (void)animationToOriginalFrame:(CGPoint)currentTouchPosition {
    NSLog(@"animationToOriginalFrame: [%@]", NSStringFromCGPoint(self.originalFrame));

    [UIView animateWithDuration:0.5 animations:^{
        self.view.center = self.originalFrame;
    } completion:^(BOOL finished) {
        if (self.startViewPosition.y < currentTouchPosition.y) {
            [self animationForInteractionView:YES];//下滑响应方法
        } else {
            [self animationForInteractionView:NO];//上滑响应方法
        }
    }];
}

//处理上下滑动
- (void)animationForInteractionView:(BOOL)upOrDown {
    //yes：下滑，no：上滑
    if (upOrDown) {
        self.InteractStatus = InteractViewStatusShow;
        [self setContentViewPositionAndTitleViewHidenStatus];
        self.contentVC.view.hidden = NO;
        [UIView transitionWithView:self.imageView
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.imageView.image = [UIImage imageNamed:@"tool-bg"];
                        }
                        completion:^(BOOL finished) {
                        }];
        [UIView animateWithDuration:0.5 animations:^{
            self.view.center = CGPointMake(self.view.center.x, INTERACT_CENTER_UNFOLD);
        } completion:^(BOOL finished) {
            CABasicAnimation* shake = [CABasicAnimation animationWithKeyPath:@"position"];
            //设置抖动幅度
            shake.fromValue = [NSValue valueWithCGPoint:self.view.center];
            shake.toValue = [NSValue valueWithCGPoint:CGPointMake(self.view.center.x, self.view.center.y - 10)];
            shake.duration = 0.1;
            shake.autoreverses = YES; //是否重复
            shake.repeatCount = 1;
            [self.view.layer addAnimation:shake forKey:@"imageView"];
            self.view.alpha = 1.0;
            self.originalFrame = self.view.center;
        }];
    }else {
        self.InteractStatus = InteractViewStatusFlod;
        [self setContentViewPositionAndTitleViewHidenStatus];
        self.contentVC.view.hidden = YES;
        NSLog(@"%@: InteractViewStatusFlod", NSStringFromSelector(_cmd));
        [UIView animateWithDuration:0.5 animations:^{
            self.view.center = CGPointMake(self.view.center.x, (-(INTERACTHEIGHT/2) + INTERACTFLODHEIGHT));
        } completion:^(BOOL finished) {
            CABasicAnimation* shake = [CABasicAnimation animationWithKeyPath:@"position"];
            //设置抖动幅度
            shake.fromValue = [NSValue valueWithCGPoint:self.view.center];
            shake.toValue = [NSValue valueWithCGPoint:CGPointMake(self.view.center.x, self.view.center.y - 10)];
            shake.duration = 0.1;
            shake.autoreverses = YES; //是否重复
            shake.repeatCount = 1;
            [self.view.layer addAnimation:shake forKey:@"imageView"];
            self.view.alpha = 1.0;
        }];
        [UIView transitionWithView:self.imageView
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.imageView.image = self.imageBgFold;
                        }
                        completion:^(BOOL finished) {
                            self.originalFrame = self.view.center;
                            [self.view bringSubviewToFront:self.iconDirectionBtn];
                        }];
    }
}

- (void)setUpContentTitleView {
    //设置展开后的 title view
    self.contentView.hidden = NO;
    [self.contentView addSubview:self.contentTitleLabel];
    self.contentTitleLabel.center = CGPointMake(self.contentView.center.x, self.contentView.center.y - 20);
}

- (void)closeInteract:(id)sender{
    [self animationToShowAndHiden:NO block:^{
        [self removeInterRactContentViewController];
    }];
}

- (void)againInteract:(id)sender {
    self.isRestart = YES;
}

- (void)resetDataWhenClose {
    self.imageView.image = [UIImage imageNamed:@"tool-bg"];
    self.InteractStatus = InteractViewStatusClose;
    [self setContentViewPositionAndTitleViewHidenStatus];
    self.contentVC.view.hidden = NO;
}

//处理隐藏和显示:yes为显示，no为隐藏
- (void)animationToShowAndHiden:(BOOL)isShow block:(void (^)())block{
    if (isShow) {
        [UIView animateWithDuration:0.5 animations:^{
            self.view.center = CGPointMake(self.view.center.x, INTERACT_CENTER_UNFOLD);
        } completion:^(BOOL finished) {
            self.InteractStatus = InteractViewStatusShow;
            block();
        }];
    }else {
        [UIView animateWithDuration:0.5 animations:^{
            self.view.center = CGPointMake(self.view.center.x, -(INTERACTHEIGHT/2));
        } completion:^(BOOL finished) {
            [self resetDataWhenClose];
            block();
        }];
    }
}

- (void)setContentViewPositionAndTitleViewHidenStatus {
    //isFolded:no为contentView在顶部，yes 为contentView在底部
    if ((self.InteractStatus == InteractViewStatusShow) || (self.InteractStatus == InteractViewStatusClose)) {
        self.contentView.frame = CGRectMake(0, 0, self.view.frame.size.width, INTERACTFLODHEIGHT);
        self.contentTitleLabel.hidden = NO;
        self.contentTitleFoldView.hidden = YES;
        self.contentTitleFoldView.center = self.contentView.center;
    }else if(self.InteractStatus == InteractViewStatusFlod) {
        self.contentView.frame = CGRectMake(0, self.view.frame.size.height - INTERACTFLODHEIGHT, self.view.frame.size.width, INTERACTFLODHEIGHT);
        self.contentTitleLabel.hidden = YES;
        self.contentTitleFoldView.hidden = NO;
        self.contentTitleFoldView.center = CGPointMake(self.view.frame.size.width/2, CGRectGetHeight(self.contentView.frame)/2 - 20);
    }
}

- (BOOL)canTouchMoved:(CGPoint)currentPoint {
    if (currentPoint.y > (INTERACTHEIGHT - 44) && currentPoint.y < (INTERACTHEIGHT)) {
        return true;
    }
    return false;
}

- (void)foldOrShowContent {
    if (self.InteractStatus == InteractViewStatusShow) {
        [self animationForInteractionView:NO];
    }else {
        [self animationForInteractionView:YES];
    }
}

- (void)registerObserver {
}

#pragma mark - touch events
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *aTouch = [touches anyObject];
    self.startTouchPosition = [aTouch locationInView:self.view];
    self.startViewPosition = self.view.center;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.canMoved || isBlinking) {
        return;
    }
    UITouch *aTouch = [touches anyObject];
    //获取当前触摸操作的位置坐标
    CGPoint loc = [aTouch locationInView:self.view];
    
    //下拉最大，上推最小的范围
    if (self.view.center.y > INTERACT_CENTER_UNFOLD || (self.view.center.y < -(INTERACTHEIGHT/2) + INTERACTFLODHEIGHT)) {
        return;
    }
    CGPoint prevloc = [aTouch previousLocationInView:self.view];
    CGRect myFrame = self.view.frame;
    
    float deltaY = loc.y - prevloc.y;
    myFrame.origin.y += deltaY;
    
    [self.view setFrame:myFrame];
    if (!isMoving) {
        isMoving = YES;
        if (self.view.center.y > INTERACT_CENTER_CHANGE_BG) {
            //展开
            self.InteractStatus = InteractViewStatusShow;
            [UIView transitionWithView:self.imageView
                              duration:0.3
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.imageView.image = [UIImage imageNamed:@"tool-bg"];
                                self.contentVC.view.hidden = NO;
                            }
                            completion:^(BOOL finished) {
                                isMoving = NO;
                                [self setContentViewPositionAndTitleViewHidenStatus];
                            }];
        }else {
            //折叠
            self.InteractStatus = InteractViewStatusFlod;
            [UIView transitionWithView:self.imageView
                              duration:0.3
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.imageView.image = self.imageBgFold;
                                self.contentVC.view.hidden = YES;
                            }
                            completion:^(BOOL finished) {
                                isMoving = NO;
                                [self setContentViewPositionAndTitleViewHidenStatus];
                            }];
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.canMoved || isBlinking) {
        return;
    }
    CGPoint currentTouchPosition = self.view.center;
    NSLog(@"touchesEnded :[%@],[%@]", NSStringFromCGPoint(currentTouchPosition), NSStringFromCGPoint(self.startViewPosition));
    
    if (fabs(self.startViewPosition.y - currentTouchPosition.y) > VERT_SWIPE_DRAG_MAX) {
        if (self.startViewPosition.y < currentTouchPosition.y) {
            [self animationForInteractionView:YES];//下滑响应方法
        } else {
            [self animationForInteractionView:NO];//上滑响应方法
        }
    }else {
        [self animationToOriginalFrame:currentTouchPosition];
    }
    //重置开始点坐标值
    self.startTouchPosition = CGPointZero;
    self.startViewPosition = CGPointZero;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    //当事件因某些原因取消时，重置开始点坐标值
    self.startTouchPosition = CGPointZero;
    self.startViewPosition = CGPointZero;
    NSLog(@"touchesCancelled");
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    isBlinking = NO;
}

#pragma mark - property
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor clearColor];
        [self setContentViewPositionAndTitleViewHidenStatus];
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        closeBtn.frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 44 - 16, 20, 44, 44);
        [closeBtn addTarget:self action:@selector(closeInteract:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:closeBtn];
        
        _againBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_againBtn setImage:[UIImage imageNamed:@"VoteAndRushAgain"] forState:UIControlStateNormal];
        _againBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, _againBtn.titleLabel.bounds.size.width);

        NSString *btnTitle = @"重新";
        [_againBtn setTitle:btnTitle forState:UIControlStateNormal];
        _againBtn.titleLabel.font = kFontSize10;
        _againBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_againBtn setTitleColor:kColorBlack33 forState:UIControlStateNormal];
        _againBtn.titleEdgeInsets = UIEdgeInsetsMake(0, _againBtn.imageView.bounds.size.width, 0, 0);
        
        CGSize textSize = SINGLELINE_TEXTSIZE(btnTitle, kFontSize10);
        CGFloat againBtnWidth = 44 + textSize.width;
        _againBtn.frame = CGRectMake(closeBtn.frame.origin.x - againBtnWidth, 20, againBtnWidth, 44);
        [_againBtn addTarget:self action:@selector(againInteract:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:_againBtn];
        
        [self.view addSubview:_contentView];
    }
    return _contentView;
}

- (UILabel *)contentTitleLabel {
    if (!_contentTitleLabel) {
        _contentTitleLabel = [UILabel new];
        _contentTitleLabel.text = @"test";
        _contentTitleLabel.font = kFontSize10;
        _contentTitleLabel.textColor = kColorBlack33;
        _contentTitleLabel.textAlignment = NSTextAlignmentCenter;
        CGSize sizeTitle = SINGLELINE_TEXTSIZE(_contentTitleLabel.text, kFontSize10);
        _contentTitleLabel.frame = CGRectMake(0, 0, sizeTitle.width * 2, sizeTitle.height);
    }
    return _contentTitleLabel;
}

- (UIButton *)iconDirectionBtn {
    if (!_iconDirectionBtn) {
        _iconDirectionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_iconDirectionBtn addTarget:self action:@selector(foldOrShowContent) forControlEvents:UIControlEventTouchUpInside];
        _iconDirectionBtn.frame = CGRectMake(self.contentView.center.x - 30, CGRectGetHeight(self.view.frame) - 37, 60, 37);
    }
    return _iconDirectionBtn;
}
@end
