//
//  DWAlbumGridNavigationBar.m
//  DWAlbumGridController
//
//  Created by Wicky on 2020/3/1.
//

#import "DWAlbumGridNavigationBar.h"

@interface DWAlbumNavigationBar (Private)

@property (nonatomic ,assign) BOOL darkMode;

@property (nonatomic ,strong) UIColor * internalBlackColor;

@property (nonatomic ,strong) UIBlurEffect * internalBlurEffect;

@property (nonatomic ,strong) UIButton * retBtn;

@end

@interface DWAlbumGridNavigationBar ()

@property (nonatomic ,strong) UILabel * titleLb;

@property (nonatomic ,strong) UIButton * cancelBtn;

@end

@implementation DWAlbumGridNavigationBar

#pragma mark --- interface method ---
-(void)configWithTitle:(NSString *)title {
    self.titleLb.text = title;
    [self refreshUI];
}

#pragma mark --- btn action ---
-(void)cancelBtnAction:(UIButton *)sender {
    if (self.cancelAction) {
        self.cancelAction(self);
    }
}

#pragma mark --- override ---
-(void)setupUI {
    [super setupUI];
    [self addSubview:self.titleLb];
    [self addSubview:self.cancelBtn];
}

-(void)refreshUI {
    [super refreshUI];
    
    CGRect btnFrame = self.cancelBtn.frame;
    btnFrame.origin.x = self.bounds.size.width - 12 - btnFrame.size.width;
    btnFrame.origin.y = self.retBtn.frame.origin.y;
    if (@available(iOS 11.0,*)) {
        btnFrame.origin.x -= self.safeAreaInsets.right;
    }
    self.cancelBtn.frame = btnFrame;
    
    [self.titleLb sizeToFit];
    btnFrame = self.titleLb.frame;
    CGFloat maxLen = CGRectGetMinX(self.cancelBtn.frame) - CGRectGetMaxX(self.retBtn.frame) - 30;
    if (btnFrame.size.width > maxLen) {
        btnFrame.size.width = maxLen;
    }
    self.titleLb.frame = btnFrame;
    CGFloat centerY = self.retBtn.center.y;
    CGFloat centerX = self.frame.size.width * 0.5;
    self.titleLb.center = CGPointMake(centerX, centerY);
}

-(void)refreshUserInterfaceStyle {
    [super refreshUserInterfaceStyle];
    self.titleLb.textColor = self.internalBlackColor;
    [self.cancelBtn setTitleColor:self.internalBlackColor forState:(UIControlStateNormal)];
}

#pragma mark --- setter/getter ---
-(UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [UILabel new];
        _titleLb.font = [UIFont boldSystemFontOfSize:17];
        _titleLb.textColor = self.internalBlackColor;
    }
    return _titleLb;
}

-(UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_cancelBtn setFrame:CGRectMake(0, 0, 44, 44)];
        _cancelBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_cancelBtn setTitle:@"取消" forState:(UIControlStateNormal)];
        [_cancelBtn setTitleColor:self.internalBlackColor forState:(UIControlStateNormal)];
        [_cancelBtn addTarget:self action:@selector(cancelBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _cancelBtn;
}

@end
