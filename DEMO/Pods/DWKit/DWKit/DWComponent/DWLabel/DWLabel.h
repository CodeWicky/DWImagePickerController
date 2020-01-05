//
//  DWInsetLabel.h
//  DWKitDemo
//
//  Created by Wicky on 2020/1/2.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWLabel : UILabel

@property (nonatomic ,assign) UIEdgeInsets marginInsets;

@property (nonatomic ,assign) UIEdgeInsets touchPaddingInsets;

@property (nonatomic ,assign) CGSize minSize;

@property (nonatomic ,assign) CGSize maxSize;

-(void)addAction:(void(^)(DWLabel * label))action;

-(void)removeAction;

@end

NS_ASSUME_NONNULL_END
