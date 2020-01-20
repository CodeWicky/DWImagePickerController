//
//  DWAlbumPreviewToolBar.m
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import "DWAlbumPreviewToolBar.h"
#import <DWKit/DWLabel.h>

@interface DWAlbumPreviewToolBar ()

@property (nonatomic ,strong) DWLabel * previewButton;

@property (nonatomic ,assign) BOOL show;

@end

@implementation DWAlbumPreviewToolBar

#pragma mark --- DWMediaPreviewToolBarProtocol method ---
-(BOOL)isShowing {
    return self.show;
}

-(void)showToolBarWithAnimated:(BOOL)animated {
    self.show = YES;
    CGRect frame = self.frame;
    frame.origin.y = self.superview.bounds.size.height - frame.size.height;
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
    frame.origin.y = self.superview.bounds.size.height;
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

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _show = YES;
    }
    return self;
}

-(void)refreshUI {
    [super refreshUI];
    if (!self.show) {
        CGRect frame =  self.frame;
        frame.origin.y = self.superview.bounds.size.height;
        self.frame = frame;
    }
}

@end
