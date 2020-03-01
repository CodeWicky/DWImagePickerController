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

-(void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.retImgView.tintColor = tintColor;
}

#pragma mark --- setter/getter ---
-(UIImageView *)retImgView {
    if (!_retImgView) {
        _retImgView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 11.5, 13, 21)];
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"DWImagePickerController" ofType:@"bundle"];
        NSBundle * bundle = [NSBundle bundleWithPath:bundlePath];
        UIImage * image =
        [[UIImage imageWithContentsOfFile:[bundle pathForResource:@"nav_ret_btn@3x" ofType:@"png"]] imageWithRenderingMode:(UIImageRenderingModeAlwaysTemplate)];
        _retImgView.image = image;
        _retImgView.userInteractionEnabled = NO;
    }
    return _retImgView;
}

@end

@interface DWAlbumPreviewNavigationBar ()<UITraitEnvironment>

@property (nonatomic ,strong) UIVisualEffectView * blurView;

@property (nonatomic ,assign) BOOL show;

@property (nonatomic ,strong) DWAlbumPreviewReturnBarButton * retBtn;

@property (nonatomic ,strong) DWLabel * selectionLb;

@property (nonatomic ,assign) NSInteger index;

@property (nonatomic ,assign) BOOL darkMode;

@property (nonatomic ,strong) UIColor * internalBlackColor;

@property (nonatomic ,strong) UIBlurEffect * internalBlurEffect;

@end

@implementation DWAlbumPreviewNavigationBar

#pragma mark --- interface method ---
+(instancetype)toolBar {
    return [self new];
}

-(void)setSelectAtIndex:(NSInteger)index {
    if (index > 0 && index != NSNotFound) {
        _index = index;
        self.selectionLb.backgroundColor = self.tintColor;
        self.selectionLb.layer.borderColor = self.tintColor.CGColor;
        self.selectionLb.text = [NSString stringWithFormat:@"%ld",(long)index];
    } else {
        _index = NSNotFound;
        self.selectionLb.backgroundColor = [UIColor clearColor];
        self.selectionLb.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.selectionLb.text = nil;
    }
    
    [self refreshUI];
}

-(void)setupDefaultValue {
    _darkModeEnabled = YES;
    _show = YES;
    self.tintColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
    _index = NSNotFound;
}

-(void)setupUI {
    [self addSubview:self.blurView];
    [self addSubview:self.retBtn];
    [self addSubview:self.selectionLb];
}

-(void)refreshUI {
    
    [self.selectionLb sizeToFit];
    CGRect btnFrame = self.selectionLb.frame;
    btnFrame.origin.x = CGRectGetWidth([UIScreen mainScreen].bounds) - CGRectGetWidth(btnFrame) - 11;//11是以44为实际响应区域后selectionLb边距与44*44的距离
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
        [UIView animateWithDuration:0.25 animations:^{
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
        [UIView animateWithDuration:0.25 animations:^{
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

#pragma mark --- UITraitEnvironment ---
///处理深色模式
-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection API_AVAILABLE(ios(8.0)) {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0,*)) {
        [self refreshUserInterfaceStyle];
    }
}

-(void)refreshUserInterfaceStyle API_AVAILABLE(ios(13.0)) {
    self.blurView.effect = self.internalBlurEffect;
    self.retBtn.tintColor = self.internalBlackColor;
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
        [self setupDefaultValue];
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

-(void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    if (_index != NSNotFound) {
        self.selectionLb.backgroundColor = tintColor;
        self.selectionLb.layer.borderColor = tintColor.CGColor;
    }
}

#pragma mark --- setter/getter ---
-(UIVisualEffectView *)blurView {
    if (!_blurView) {
        _blurView = [[UIVisualEffectView alloc] initWithEffect:self.internalBlurEffect];
        _blurView.frame = self.bounds;
        _blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _blurView;
}

-(DWAlbumPreviewReturnBarButton *)retBtn {
    if (!_retBtn) {
        _retBtn = [DWAlbumPreviewReturnBarButton buttonWithType:(UIButtonTypeCustom)];
        [_retBtn setFrame:CGRectMake(0, 0, 44, 44)];
        [_retBtn addTarget:self action:@selector(retBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
        _retBtn.tintColor = self.internalBlackColor;
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
        _selectionLb.layer.borderColor = [UIColor lightGrayColor].CGColor;
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

-(void)setDarkModeEnabled:(BOOL)darkModeEnabled {
    if (_darkModeEnabled != darkModeEnabled) {
        _darkModeEnabled = darkModeEnabled;
        if (@available(iOS 13.0,*)) {
            [self refreshUserInterfaceStyle];
        }
    }
}

-(BOOL)darkMode {
    if (self.darkModeEnabled) {
        if (@available(iOS 13.0,*)) {
            if ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    return NO;
}

-(UIColor *)internalBlackColor {
    if (self.darkMode) {
        return [UIColor whiteColor];
    }
    return [UIColor blackColor];
}

-(UIBlurEffect *)internalBlurEffect {
    if (self.darkMode) {
        return [UIBlurEffect effectWithStyle:(UIBlurEffectStyleDark)];
    }
    return [UIBlurEffect effectWithStyle:(UIBlurEffectStyleExtraLight)];
}

@end
