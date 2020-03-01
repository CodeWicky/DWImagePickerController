//
//  DWAlbumPreviewNavigationBar.m
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import "DWAlbumPreviewNavigationBar.h"
#import <DWKit/DWLabel.h>

@interface DWAlbumPreviewNavigationBar ()

@property (nonatomic ,assign) BOOL show;

@property (nonatomic ,strong) DWLabel * selectionLb;

@property (nonatomic ,assign) NSInteger index;

//@property (nonatomic ,assign) BOOL darkMode;
//
//@property (nonatomic ,strong) UIColor * internalBlackColor;
//
//@property (nonatomic ,strong) UIBlurEffect * internalBlurEffect;

@end

@implementation DWAlbumPreviewNavigationBar

#pragma mark --- interface method ---
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

#pragma mark --- btn action ---
-(void)retBtnAction:(UIButton *)sender {
    if (self.retAction) {
        self.retAction(self);
    }
}

#pragma mark --- override ---
-(void)setupDefaultValue {
    [super setupDefaultValue];
    _show = YES;
    self.tintColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
    _index = NSNotFound;
}

-(void)setupUI {
    [super setupUI];
    [self addSubview:self.selectionLb];
}

-(void)refreshUI {
    [super refreshUI];
    
    if (!self.show) {
        CGRect btnFrame = self.frame;
        btnFrame.origin.y = -CGRectGetHeight(btnFrame);
        self.frame = btnFrame;
    }
    
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
}

-(void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    if (_index != NSNotFound) {
        self.selectionLb.backgroundColor = tintColor;
        self.selectionLb.layer.borderColor = tintColor.CGColor;
    }
}

#pragma mark --- setter/getter ---
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

@end
