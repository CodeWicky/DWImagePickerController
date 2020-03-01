//
//  DWAlbumNavigationBar.m
//  DWAlbumGridController
//
//  Created by Wicky on 2020/3/1.
//

#import "DWAlbumNavigationBar.h"

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

@interface DWAlbumNavigationBar ()<UITraitEnvironment>

@property (nonatomic ,strong) UIVisualEffectView * blurView;

@property (nonatomic ,strong) DWAlbumPreviewReturnBarButton * retBtn;

@property (nonatomic ,assign) BOOL darkMode;

@property (nonatomic ,strong) UIColor * internalBlackColor;

@property (nonatomic ,strong) UIBlurEffect * internalBlurEffect;

@end

@implementation DWAlbumNavigationBar

@synthesize selectionManager,toolBarHeight;

#pragma mark --- interface method ---
+(instancetype)toolBar {
    return [self new];
}

-(void)setupDefaultValue {
    _darkModeEnabled = YES;
    self.toolBarHeight = 44;
}

-(void)setupUI {
    [self addSubview:self.blurView];
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
    }
    [self.retBtn setFrame:btnFrame];

    btnFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, CGRectGetMaxY(btnFrame));
    self.frame = btnFrame;
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

#pragma mark --- override ---
-(void)configWithSelectionManager:(DWAlbumSelectionManager *)selectionManager {
    //Nothing to do.
}

-(void)refreshSelection {
    //Nothing to do.
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
