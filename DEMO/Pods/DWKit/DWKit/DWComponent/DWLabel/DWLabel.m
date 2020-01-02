//
//  DWInsetLabel.m
//  DWKitDemo
//
//  Created by Wicky on 2020/1/2.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWLabel.h"

@implementation DWLabel

#pragma mark --- margin insets 相关 ---
#pragma mark --- override ---
-(void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.marginInsets)];
}

-(CGSize)sizeThatFits:(CGSize)size {
    size = [super sizeThatFits:size];
    size.width += self.marginInsets.left + self.marginInsets.right;
    size.height += self.marginInsets.top + self.marginInsets.bottom;
    return size;
}

-(CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width += self.marginInsets.left + self.marginInsets.right;
    size.height += self.marginInsets.top + self.marginInsets.bottom;
    return size;
}

-(void)setText:(NSString *)text {
    [super setText:text];
    [self invalidateIntrinsicContentSize];
}

-(void)setFont:(UIFont *)font {
    [super setFont:font];
    [self invalidateIntrinsicContentSize];
}

#pragma mark --- setter/getter ---
-(void)setMarginInsets:(UIEdgeInsets)marginInsets {
    _marginInsets = marginInsets;
    [self invalidateIntrinsicContentSize];
}

#pragma mark --- touch padding 相关 ---
#pragma mark --- override ---
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (UIEdgeInsetsEqualToEdgeInsets(self.touchPaddingInsets, UIEdgeInsetsZero)) {
        return [super pointInside:point withEvent:event];
    }
    CGRect rect = self.bounds;
    rect.origin.x -= self.touchPaddingInsets.left;
    rect.origin.y -= self.touchPaddingInsets.top;
    rect.size.width += self.touchPaddingInsets.left + self.touchPaddingInsets.right;
    rect.size.height += self.touchPaddingInsets.top + self.touchPaddingInsets.bottom;
    return CGRectContainsPoint(rect, point);
}

@end
