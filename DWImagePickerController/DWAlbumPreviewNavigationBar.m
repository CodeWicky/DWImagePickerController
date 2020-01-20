//
//  DWAlbumPreviewNavigationBar.m
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import "DWAlbumPreviewNavigationBar.h"
#import <DWKit/DWLabel.h>

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

@property (nonatomic ,strong) DWLabel * selectionLb;

@end

@implementation DWAlbumPreviewNavigationBar

#pragma mark --- interface method ---
+(instancetype)toolBar {
    return [self new];
}

-(void)setSelectAtIndex:(NSInteger)index {
    if (index > 0 && index != NSNotFound) {
        self.selectionLb.backgroundColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
        self.selectionLb.text = [NSString stringWithFormat:@"%ld",(long)index];
    } else {
        self.selectionLb.backgroundColor = [UIColor clearColor];
        self.selectionLb.text = nil;
    }
    
    [self refreshUI];
}

#pragma mark --- tool method ---
-(void)setupUI {
    UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:(UIBlurEffectStyleExtraLight)];
    UIVisualEffectView * blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:blurView];
    [self addSubview:self.retBtn];
    [self addSubview:self.selectionLb];
}

-(void)refreshUI {
    
    [self.selectionLb sizeToFit];
    CGRect btnFrame = self.selectionLb.frame;
    btnFrame.origin.x = CGRectGetWidth([UIApplication sharedApplication].statusBarFrame) - CGRectGetWidth(btnFrame) - 11;//11是以44为实际响应区域后selectionLb边距与44*44的距离
    btnFrame.origin.y = 11;
    if (@available(iOS 11.0,*)) {
        btnFrame.origin.y += self.safeAreaInsets.top;
        btnFrame.origin.x -= self.safeAreaInsets.right;
    } else {
        btnFrame.origin.y += CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame);
    }
    self.selectionLb.frame = btnFrame;
    
    btnFrame = self.retBtn.frame;
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

-(CGFloat)baseline {
    return self.frame.size.height;
}

#pragma mark --- btn action ---
-(void)retBtnAction:(UIButton *)sender {
    if (self.retAction) {
        self.retAction(self);
    }
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

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

#pragma mark --- setter/getter ---
-(DWAlbumPreviewReturnBarButton *)retBtn {
    if (!_retBtn) {
        _retBtn = [DWAlbumPreviewReturnBarButton buttonWithType:(UIButtonTypeCustom)];
        [_retBtn setFrame:CGRectMake(0, 0, 44, 44)];
        [_retBtn addTarget:self action:@selector(retBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _retBtn;
}

-(DWLabel *)selectionLb {
    if (!_selectionLb) {
        _selectionLb = [[DWLabel alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        _selectionLb.minSize = CGSizeMake(22, 22);
        _selectionLb.maxSize = CGSizeMake(44, 22);
        _selectionLb.font = [UIFont systemFontOfSize:13];
        _selectionLb.adjustsFontSizeToFitWidth = YES;
        _selectionLb.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _selectionLb.touchPaddingInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        _selectionLb.marginInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        _selectionLb.textColor = [UIColor whiteColor];
        _selectionLb.backgroundColor = [UIColor clearColor];
        _selectionLb.layer.borderColor = [UIColor lightGrayColor].CGColor;;
        _selectionLb.layer.borderWidth = 2;
        _selectionLb.layer.cornerRadius = 11;
        _selectionLb.layer.masksToBounds = YES;
        _selectionLb.textAlignment = NSTextAlignmentCenter;
        __weak typeof(self) weakSelf = self;
        [_selectionLb addAction:^(DWLabel * _Nonnull label) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.selectionAction) {
                strongSelf.selectionAction(strongSelf);
            }
        }];
        _selectionLb.userInteractionEnabled = YES;
    }
    return _selectionLb;
}

@end
