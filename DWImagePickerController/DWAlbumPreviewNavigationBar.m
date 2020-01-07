//
//  DWAlbumPreviewNavigationBar.m
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import "DWAlbumPreviewNavigationBar.h"

@interface DWAlbumPreviewReturnBarButton : UIButton

@property (nonatomic ,strong) UIImageView * retImgView;

@end

@implementation DWAlbumPreviewReturnBarButton

#pragma mark --- tool method ---
-(void)setupUI {
    [self addSubview:self.retImgView];
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

#pragma mark --- setter/getter ---
-(UIImageView *)retImgView {
    if (!_retImgView) {
        _retImgView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 11.5, 13, 21)];
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"DWImagePickerController" ofType:@"bundle"];
        NSBundle * bundle = [NSBundle bundleWithPath:bundlePath];
        UIImage * image = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"nav_ret_btn@3x" ofType:@"png"]];
        _retImgView.image = image;
        _retImgView.userInteractionEnabled = NO;
    }
    return _retImgView;
}

@end

@interface DWAlbumPreviewNavigationBar ()

@property (nonatomic ,assign) BOOL show;

@property (nonatomic ,strong) DWAlbumPreviewReturnBarButton * retBtn;

@end

@implementation DWAlbumPreviewNavigationBar

#pragma mark --- interface method ---
+(instancetype)toolBar {
    return [self new];
}

#pragma mark --- tool method ---
-(void)setupUI {
    UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:(UIBlurEffectStyleExtraLight)];
    UIVisualEffectView * blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:blurView];
    [self addSubview:self.retBtn];
}

-(void)refreshUI {
    CGRect btnFrame = self.retBtn.frame;
    btnFrame.origin.x = 0;
    if (@available(iOS 11.0,*)) {
        btnFrame.origin.y = self.safeAreaInsets.top;
        btnFrame.origin.x = self.safeAreaInsets.left;
        ///为了保证跟系统按钮位置搞好对上
        if (btnFrame.origin.x > 0) {
            btnFrame.origin.x -= 5;
        }
    } else {
        btnFrame.origin.y = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame);
        NSLog(@"%f",btnFrame.origin.y);
    }
    [self.retBtn setFrame:btnFrame];
    
    if (self.show) {
        btnFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, CGRectGetMaxY(btnFrame));
    } else {
        btnFrame = CGRectMake(0,-CGRectGetMaxY(btnFrame), [UIScreen mainScreen].bounds.size.width, CGRectGetMaxY(btnFrame));
    }
    
    self.frame = btnFrame;
}

#pragma mark --- DWMediaPreviewTopToolBarProtocol method ---
-(BOOL)isShowing {
    return self.show;
}

-(void)showToolBarWithAnimated:(BOOL)animated {
    self.show = YES;
    CGRect frame = self.frame;
    frame.origin.y = 0;
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.frame = frame;
        }];
    } else {
        self.frame = frame;
    }
}

-(void)hideToolBarWithAnimated:(BOOL)animated {
    CGRect frame = self.frame;
    frame.origin.y = - frame.size.height;
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.frame = frame;
        } completion:^(BOOL finished) {
            self.show = NO;
        }];
    } else {
        self.frame = frame;
        self.show = NO;
    }
}

-(CGFloat)baseLineForBadge {
    return self.frame.size.height;
}

#pragma mark --- btn action ---
-(void)retAction:(UIButton *)sender {
    
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _show = YES;
        [self setupUI];
        [self refreshUI];
    }
    return self;
}

-(void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    [self refreshUI];
}

#pragma mark --- setter/getter ---
-(DWAlbumPreviewReturnBarButton *)retBtn {
    if (!_retBtn) {
        _retBtn = [DWAlbumPreviewReturnBarButton buttonWithType:(UIButtonTypeCustom)];
        [_retBtn setFrame:CGRectMake(0, 0, 44, 44)];
        [_retBtn addTarget:self action:@selector(retAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _retBtn;
}

@end
