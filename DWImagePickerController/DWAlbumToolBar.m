//
//  DWAlbumToolBar.m
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import "DWAlbumToolBar.h"
#import <DWKit/DWLabel.h>

@interface DWAlbumToolBar ()<UITraitEnvironment>

@property (nonatomic ,strong) UIVisualEffectView * blurView;

@property (nonatomic ,strong) DWLabel * previewButton;

@property (nonatomic ,strong) UIView * originCtn;

@property (nonatomic ,strong) UIView * originCircle;

@property (nonatomic ,strong) UIView * originIndicator;

@property (nonatomic ,strong) DWLabel * originLb;

@property (nonatomic ,strong) DWLabel * sendButton;

///深色模式适配
@property (nonatomic ,assign) BOOL darkMode;

@property (nonatomic ,strong) UIColor * internalBlackColor;

@property (nonatomic ,strong) UIBlurEffect * internalBlurEffect;

@end

@implementation DWAlbumToolBar

@synthesize selectionManager,toolBarHeight;

#pragma mark --- interface method ---
+(instancetype)toolBar {
    return [self new];
}

#pragma mark --- tool method ---
-(void)setupDefaultValue {
    _darkModeEnabled = YES;
    self.tintColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
    self.toolBarHeight = 49;
}

-(void)setupUI {
    [self addSubview:self.blurView];
    [self addSubview:self.previewButton];
    [self addSubview:self.originCtn];
    [self.originCtn addSubview:self.originCircle];
    [self.originCircle addSubview:self.originIndicator];
    [self.originCtn addSubview:self.originLb];
    [self addSubview:self.sendButton];
}

-(void)refreshUI {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    if (self.selectionManager.selections.count) {
        self.previewButton.userInteractionEnabled = YES;
        self.previewButton.textColor = self.internalBlackColor;
    } else {
        self.previewButton.userInteractionEnabled = NO;
        self.previewButton.textColor = [UIColor lightGrayColor];
    }
    
    [self.previewButton sizeToFit];
    CGRect btnFrame = self.previewButton.frame;
    CGSize btnSize = btnFrame.size;
    btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
    btnFrame.origin.x = 15;
    
    if (@available(iOS 11.0,*)) {
        btnFrame.origin.x += self.safeAreaInsets.left;
    }
    
    self.previewButton.frame = btnFrame;
    
    if (self.selectionManager.useOriginImage) {
        self.originIndicator.hidden = NO;
    } else {
        self.originIndicator.hidden = YES;
    }
    btnFrame = self.originCircle.frame;
    btnSize = btnFrame.size;
    btnFrame.origin.x = 0;
    btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
    self.originCircle.frame = btnFrame;
    
    [self.originLb sizeToFit];
    btnFrame = self.originLb.frame;
    btnSize = btnFrame.size;
    btnFrame.origin.x = self.originCircle.frame.size.width + 2;
    btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
    self.originLb.frame = btnFrame;
    
    btnFrame.size.width = CGRectGetMaxX(btnFrame);
    btnFrame.size.height = self.toolBarHeight;
    btnFrame.origin.x = (screenWidth - btnFrame.size.width) * 0.5;
    btnFrame.origin.y = 0;
    self.originCtn.frame = btnFrame;
    
    if (self.selectionManager.selections.count) {
        self.sendButton.text = [NSString stringWithFormat:@"完成(%lu)",(unsigned long)self.selectionManager.selections.count];
        self.sendButton.userInteractionEnabled = YES;
        self.sendButton.backgroundColor = self.tintColor;
    } else {
        self.sendButton.text = @"完成";
        self.sendButton.userInteractionEnabled = NO;
        self.sendButton.backgroundColor = [UIColor lightGrayColor];
    }
    [self.sendButton sizeToFit];
    btnFrame = self.sendButton.frame;
    btnSize = btnFrame.size;
    btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
    btnFrame.origin.x = screenWidth - 15 - btnSize.width;
    
    if (@available(iOS 11.0,*)) {
        btnFrame.origin.x -= self.safeAreaInsets.right;
    }
    
    self.sendButton.frame = btnFrame;
    
    btnFrame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - self.toolBarHeight, screenWidth, self.toolBarHeight);
    
    if (@available(iOS 11.0,*)) {
        btnFrame.size.height += self.safeAreaInsets.bottom;
        btnFrame.origin.y -= self.safeAreaInsets.bottom;
    }
    
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
    if (self.previewButton.userInteractionEnabled) {
        self.previewButton.textColor = self.internalBlackColor;
    }
    self.originLb.textColor = self.internalBlackColor;
}

#pragma mark --- btn action ---
-(void)originBtnAction:(UITapGestureRecognizer *)sender {
    if (self.originImageAction) {
        self.originImageAction(self);
    }
}

#pragma mark --- override ---
-(void)refreshSelection {
    [self refreshUI];
}

- (void)configWithSelectionManager:(DWAlbumSelectionManager *)selectionManager {
    self.selectionManager = selectionManager;
}

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
    ///这里用touchBegan来避免事件穿透至底层视图中实现touchBegan的事件中。只要空实现即可
}

-(void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.originIndicator.backgroundColor = tintColor;
    if (self.selectionManager.selections.count) {
        self.sendButton.backgroundColor = tintColor;
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

-(DWLabel *)previewButton {
    if (!_previewButton) {
        _previewButton = [DWLabel new];
        _previewButton.font = [UIFont systemFontOfSize:17];
        _previewButton.text = @"预览";
        _previewButton.textColor = self.internalBlackColor;
        __weak typeof(self)weakSelf = self;
        [_previewButton addAction:^(DWLabel * _Nonnull label) {
            if (weakSelf.previewAction) {
                weakSelf.previewAction(weakSelf);
            }
        }];
    }
    return _previewButton;
}

-(UIView *)originCtn {
    if (!_originCtn) {
        _originCtn = [UIView new];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(originBtnAction:)];
        [_originCtn addGestureRecognizer:tap];
    }
    return _originCtn;
}

-(UIView *)originCircle {
    if (!_originCircle) {
        _originCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
        _originCircle.layer.cornerRadius = 9;
        _originCircle.layer.borderWidth = 2;
        _originCircle.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _originCircle.userInteractionEnabled = NO;
    }
    return _originCircle;
}

-(UIView *)originIndicator {
    if (!_originIndicator) {
        _originIndicator = [[UIView alloc] initWithFrame:CGRectMake(4, 4, 10, 10)];
        _originIndicator.backgroundColor = self.tintColor;
        _originIndicator.userInteractionEnabled = NO;
        _originIndicator.layer.cornerRadius = 5;
        _originIndicator.layer.masksToBounds = YES;
    }
    return _originIndicator;
}

-(DWLabel *)originLb {
    if (!_originLb) {
        _originLb = [DWLabel new];
        _originLb.font = [UIFont systemFontOfSize:17];
        _originLb.text = @"原图";
        _originLb.textColor = self.internalBlackColor;
        _originLb.userInteractionEnabled = NO;
    }
    return _originLb;
}

-(DWLabel *)sendButton {
    if (!_sendButton) {
        _sendButton = [DWLabel new];
        _sendButton.font = [UIFont systemFontOfSize:17];
        _sendButton.textColor = [UIColor whiteColor];
        _sendButton.marginInsets = UIEdgeInsetsMake(5, 10, 5, 10);
        _sendButton.layer.cornerRadius = 5;
        _sendButton.layer.masksToBounds = YES;
        __weak typeof(self)weakSelf = self;
        [_sendButton addAction:^(DWLabel * _Nonnull label) {
            if (weakSelf.sendAction) {
                weakSelf.sendAction(weakSelf);
            }
        }];
    }
    return _sendButton;
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
