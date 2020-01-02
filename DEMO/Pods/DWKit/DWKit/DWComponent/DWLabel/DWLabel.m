//
//  DWInsetLabel.m
//  DWKitDemo
//
//  Created by Wicky on 2020/1/2.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWLabel.h"

@interface DWLabel ()

@property (nonatomic ,strong) NSMutableArray * innerConstraints;

@end

@implementation DWLabel

#pragma mark --- margin insets 相关 ---
#pragma mark --- tool method ---
-(void)addInnerConstraintsIfNeeded {
    if (!self.innerConstraints) {
        NSMutableArray * constraints = [NSMutableArray arrayWithCapacity:2];
        if (self.maxSize.width > 0) {
            NSLayoutConstraint * widthMaxConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.maxSize.width - self.marginInsets.left - self.marginInsets.right];
            
            if (widthMaxConstraint) {
                widthMaxConstraint.priority = UILayoutPriorityRequired;
                [constraints addObject:widthMaxConstraint];
            }
        }
        
        if (self.minSize.width > 0) {
            NSLayoutConstraint * widthMinConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.minSize.width - self.marginInsets.left - self.marginInsets.right];
            
            if (widthMinConstraint) {
                widthMinConstraint.priority = UILayoutPriorityRequired;
                [constraints addObject:widthMinConstraint];
            }
        }
        
        if (self.maxSize.height > 0) {
            NSLayoutConstraint * heightMaxConstraints = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.maxSize.height - self.marginInsets.top - self.marginInsets.bottom];
            if (heightMaxConstraints) {
                heightMaxConstraints.priority = UILayoutPriorityRequired;
                [constraints addObject:heightMaxConstraints];
            }
        }
        
        if (self.minSize.height > 0) {
            NSLayoutConstraint * heightMinConstraints = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.minSize.height - self.marginInsets.top - self.marginInsets.bottom];
            if (heightMinConstraints) {
                heightMinConstraints.priority = UILayoutPriorityRequired;
                [constraints addObject:heightMinConstraints];
            }
        }
        
        if (constraints.count) {
            [self addConstraints:constraints];
        }
        
        self.innerConstraints = constraints;
    }
}

-(void)removeInnerConstraintsIfNeeded {
    if (self.innerConstraints) {
        [self removeConstraints:self.constraints];
        self.innerConstraints = nil;
    }
}

#pragma mark --- override ---
-(void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.marginInsets)];
}

-(void)sizeToFit {
    CGSize fixMaxSize = CGSizeZero;
    if (self.maxSize.width > 0) {
        fixMaxSize.width = self.maxSize.width - self.marginInsets.left - self.marginInsets.right;
    }
    CGSize size = [super sizeThatFits:fixMaxSize];
    size.width += self.marginInsets.left + self.marginInsets.right;
    size.height += self.marginInsets.top + self.marginInsets.bottom;
    
    if (size.width < self.minSize.width) {
        size.width = self.minSize.width;
    } else if (self.maxSize.width > 0 && size.width > self.maxSize.width) {
        size.width = self.maxSize.width;
    }
    
    if (size.height < self.minSize.height) {
        size.height = self.minSize.height;
    } else if (self.maxSize.height > 0 && size.height > self.maxSize.height) {
        size.height = self.maxSize.height;
    }
    
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
    
}

-(CGSize)intrinsicContentSize {
    [self addInnerConstraintsIfNeeded];
    
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
    if (!UIEdgeInsetsEqualToEdgeInsets(marginInsets, _marginInsets)) {
        _marginInsets = marginInsets;
        [self removeInnerConstraintsIfNeeded];
        [self invalidateIntrinsicContentSize];
    }
}

-(void)setMinSize:(CGSize)minSize {
    if (!CGSizeEqualToSize(minSize, _minSize)) {
        _minSize = minSize;
        [self removeInnerConstraintsIfNeeded];
        [self invalidateIntrinsicContentSize];
    }
}

-(void)setMaxSize:(CGSize)maxSize {
    if (!CGSizeEqualToSize(maxSize, _maxSize)) {
        _maxSize = maxSize;
        [self removeInnerConstraintsIfNeeded];
        [self invalidateIntrinsicContentSize];
    }
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
