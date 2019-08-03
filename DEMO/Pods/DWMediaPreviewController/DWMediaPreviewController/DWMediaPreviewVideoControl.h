//
//  DWMediaPreviewVideoControl.h
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/7/24.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWMediaPreviewVideoControl : UIView

@property (nonatomic ,assign) NSTimeInterval totalTime;

@property (nonatomic ,assign ,readonly) NSTimeInterval currentTime;

@property (nonatomic ,copy) void(^playBtnClicked)(BOOL toPlay);

@property (nonatomic ,copy) void(^sliderValueChanged)(NSTimeInterval totalDuration,CGFloat percent);
@property (nonatomic ,copy) void(^sliderStatusChanged)(BOOL touchDown);

-(void)updateCurrentTime:(NSTimeInterval)time;

-(void)updateControlStatus:(BOOL)playing;

@end

NS_ASSUME_NONNULL_END
