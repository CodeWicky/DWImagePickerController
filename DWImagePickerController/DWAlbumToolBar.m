//
//  DWAlbumToolBar.m
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import "DWAlbumToolBar.h"
#import <DWKit/DWLabel.h>

@implementation DWAlbumBaseToolBar

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _toolBarHeight = 49;
    }
    return self;
}

-(void)configWithSelectionManager:(DWAlbumSelectionManager *)seletionManager {
    _selectionManager = seletionManager;
}

-(void)refreshSelection {
    //Override this.
}

@end

@interface DWAlbumToolBar ()

@property (nonatomic ,strong) DWLabel * previewButton;

@property (nonatomic ,strong) UIView * originCircle;

@property (nonatomic ,strong) UIView * originIndicator;

@property (nonatomic ,strong) DWLabel * originLb;

@property (nonatomic ,strong) DWLabel * sendButton;

@end

@implementation DWAlbumToolBar

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
    [self addSubview:self.previewButton];
    [self addSubview:self.originCircle];
    [self.originCircle addSubview:self.originIndicator];
    [self addSubview:self.originLb];
    [self addSubview:self.sendButton];
}

-(void)refreshUI {
    
    if (self.selectionManager.selections.count) {
        self.previewButton.userInteractionEnabled = YES;
        self.previewButton.textColor = [UIColor blackColor];
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
    btnFrame.origin.x = [UIScreen mainScreen].bounds.size.width * 0.5 - 1 - btnSize.width;
    btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
    self.originCircle.frame = btnFrame;
    
    [self.originLb sizeToFit];
    btnFrame = self.originLb.frame;
    btnSize = btnFrame.size;
    btnFrame.origin.x = [UIScreen mainScreen].bounds.size.width * 0.5 + 1;
    btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
    self.originLb.frame = btnFrame;
    
    if (self.selectionManager.selections.count) {
        self.sendButton.text = [NSString stringWithFormat:@"发送(%ld)",self.selectionManager.selections.count];
        self.sendButton.userInteractionEnabled = YES;
        self.sendButton.backgroundColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
    } else {
        self.sendButton.text = @"发送";
        self.sendButton.userInteractionEnabled = NO;
        self.sendButton.backgroundColor = [UIColor lightGrayColor];
    }
    [self.sendButton sizeToFit];
    btnFrame = self.sendButton.frame;
    btnSize = btnFrame.size;
    btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
    btnFrame.origin.x = [UIScreen mainScreen].bounds.size.width - 15 - btnSize.width;
    
    if (@available(iOS 11.0,*)) {
        btnFrame.origin.x -= self.safeAreaInsets.right;
    }
    
    self.sendButton.frame = btnFrame;
    
    btnFrame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - self.toolBarHeight, [UIScreen mainScreen].bounds.size.width, self.toolBarHeight);
    
    if (@available(iOS 11.0,*)) {
        btnFrame.size.height += self.safeAreaInsets.bottom;
        btnFrame.origin.y -= self.safeAreaInsets.bottom;
    }
    
    self.frame = btnFrame;
}

#pragma mark --- override ---
-(void)refreshSelection {
    [super refreshSelection];
    [self refreshUI];
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
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
-(DWLabel *)previewButton {
    if (!_previewButton) {
        _previewButton = [DWLabel new];
        _previewButton.font = [UIFont systemFontOfSize:17];
        _previewButton.text = @"预览";
        _previewButton.textColor = [UIColor blackColor];
        __weak typeof(self)weakSelf = self;
        [_previewButton addAction:^(DWLabel * _Nonnull label) {
            if (weakSelf.previewAction) {
                weakSelf.previewAction(weakSelf);
            }
        }];
    }
    return _previewButton;
}

-(UIView *)originCircle {
    if (!_originCircle) {
        _originCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
        _originCircle.layer.cornerRadius = 9;
        _originCircle.layer.borderWidth = 2;
        _originCircle.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }
    return _originCircle;
}

-(UIView *)originIndicator {
    if (!_originIndicator) {
        _originIndicator = [[UIView alloc] initWithFrame:CGRectMake(4, 4, 10, 10)];
        _originIndicator.backgroundColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
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
        _originLb.textColor = [UIColor blackColor];
        _originLb.userInteractionEnabled  = YES;
        _originLb.touchPaddingInsets = UIEdgeInsetsMake(0, 2 + 18, 0, 0);
        __weak typeof(self)weakSelf = self;
        [_originLb addAction:^(DWLabel * _Nonnull label) {
            if (weakSelf.originImageAction) {
                weakSelf.originImageAction(weakSelf);
            }
        }];
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

@end
