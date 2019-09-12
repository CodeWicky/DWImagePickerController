//
//  DWMediaPreviewLoading.m
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/9/4.
//

#import "DWMediaPreviewLoading.h"
#import <DWKit/DWOperationCancelFlag.h>

#define Loading_W (60)
#define CGFLOATEQUAL(a,b) (fabs(a - b) <= __FLT_EPSILON__)

@interface DWMediaPreviewLoading ()

@property (nonatomic ,strong) CAShapeLayer * progressLayer;

@property (nonatomic ,strong) DWOperationCancelFlag * cancelFlag;

@property (nonatomic ,copy) CancelFlag flag;

@end

@implementation DWMediaPreviewLoading
@synthesize isShowing = _isShowing;
@synthesize progress = _progress;

#pragma mark --- interface method ---
+(instancetype)loading {
    return [self new];
}

#pragma mark --- protocol method ---
-(void)showLoading {
    self.flag = [self.cancelFlag restartAnCancelFlag];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.flag && !self.flag()) {
            [self _internalShowLoading];
        }
    });
}

-(void)updateProgress:(CGFloat)progress {
    if (self.isShowing) {
        _progress = MAX(0, MIN(1, progress));
        self.progressLayer.strokeEnd = _progress;
        if (CGFLOATEQUAL(_progress, 1)) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hideLoading];
            });
        }
    }
}

-(void)hideLoading {
    [self.cancelFlag cancel];
    self.hidden = YES;
}

#pragma mark --- tool method ---
-(void)setupUI {
    self.hidden = YES;
    self.alpha = 0.5;
    self.backgroundColor = [UIColor blackColor];
    self.layer.cornerRadius = Loading_W * 0.5;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 1;
    
    [self.layer addSublayer:self.progressLayer];
}

-(void)_internalShowLoading {
    self.hidden = NO;
}

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super initWithFrame:CGRectMake(0, 0, Loading_W, Loading_W)]) {
        [self setupUI];
    }
    return self;
}

#pragma mark --- setter/getter ---
-(CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        CGFloat radius = (Loading_W * 0.5 - 2) * 0.5;
        UIBezierPath * path = [UIBezierPath bezierPath];
        
        [path moveToPoint:CGPointMake(Loading_W * 0.5, Loading_W * 0.5 - radius)];
        [path addArcWithCenter:CGPointMake(Loading_W * 0.5, Loading_W * 0.5) radius:radius startAngle:- M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];
        
        _progressLayer.path = path.CGPath;
        _progressLayer.strokeColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
        _progressLayer.lineWidth = radius * 2;
        _progressLayer.strokeEnd = 0;
    }
    return _progressLayer;
}

-(DWOperationCancelFlag *)cancelFlag {
    if (!_cancelFlag) {
        _cancelFlag = [DWOperationCancelFlag new];
    }
    return _cancelFlag;
}

-(BOOL)isShowing {
    return !self.hidden;
}

@end
