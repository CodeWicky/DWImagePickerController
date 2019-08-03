//
//  DWMediaPreviewVideoControl.m
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/7/24.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWMediaPreviewVideoControl.h"

@interface DWMediaPreviewVideoControl ()

@property (nonatomic ,strong) UIVisualEffectView * backgroundView;

@property (nonatomic ,strong) UIButton * playBtn;

@property (nonatomic ,strong) UILabel * currentTimeLb;

@property (nonatomic ,strong) UILabel * totalTimeLb;

@property (nonatomic ,strong) UISlider * timeSlider;

@property (nonatomic ,strong) NSBundle * imageBundle;

@end

@implementation DWMediaPreviewVideoControl

#pragma mark --- interface method ---
-(void)updateCurrentTime:(NSTimeInterval)time {
    [self updateCurrentTime:time configSlider:YES];
}

-(void)updateControlStatus:(BOOL)playing {
    self.playBtn.selected = playing;
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

-(void)setFrame:(CGRect)frame {
    if (!CGRectEqualToRect(frame, self.frame)) {
        [super setFrame:frame];
        [self setupConstraints];
    }
}

#pragma mark --- tool method ---
-(void)setupUI {
    ///此处在背景图上添加滑动手势，防止当事件传递给slider但是slider无法响应事件（没有点击到thumb时）事件透传到collectionView导致col开始滚动
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(breakResponderChain)];
    [self addGestureRecognizer:pan];
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;
    [self addSubview:self.backgroundView];
    [self addSubview:self.playBtn];
    [self addSubview:self.currentTimeLb];
    [self addSubview:self.totalTimeLb];
    [self addSubview:self.timeSlider];
}

-(void)setupConstraints {
    if (!CGRectEqualToRect(self.bounds, self.backgroundView.frame)) {
        self.backgroundView.frame = self.bounds;
    }
    if (self.playBtn.center.y != self.bounds.size.height * 0.5) {
        CGPoint center = self.playBtn.center;
        center.y = self.bounds.size.height * 0.5;
        self.playBtn.center = center;
    }
    [self.totalTimeLb sizeToFit];
    if (self.totalTimeLb.frame.origin.x != self.bounds.size.width - 15 - self.totalTimeLb.frame.size.width || self.totalTimeLb.center.y != self.bounds.size.height * 0.5) {
        CGRect frame = self.totalTimeLb.frame;
        frame.origin.x = self.bounds.size.width - 15 - self.totalTimeLb.frame.size.width;
        frame.origin.y = (self.bounds.size.height - self.totalTimeLb.frame.size.height) * 0.5;
        self.totalTimeLb.frame = frame;
    }
    
    if (self.currentTimeLb.frame.size.width != self.totalTimeLb.frame.size.width || self.currentTimeLb.frame.origin.x != CGRectGetMaxX(self.playBtn.frame) + 10 || self.currentTimeLb.center.y != self.bounds.size.height * 0.5) {
        CGRect frame = self.totalTimeLb.frame;
        frame.origin.x = CGRectGetMaxX(self.playBtn.frame) + 10;
        ///宽度做修正，防止字符宽度不同导致的偏差
        frame.size.width = frame.size.width + self.totalTimeLb.text.length;
        self.currentTimeLb.frame = frame;
    }
    
    if (self.timeSlider.frame.origin.x != CGRectGetMaxX(self.currentTimeLb.frame) + 10 || CGRectGetMaxX(self.currentTimeLb.frame) != CGRectGetMinX(self.totalTimeLb.frame) - 10 || self.timeSlider.center.y != self.bounds.size.height * 0.5) {
        CGRect frame = self.timeSlider.frame;
        frame.origin.x = CGRectGetMaxX(self.currentTimeLb.frame) + 10;
        frame.size.width = CGRectGetMinX(self.totalTimeLb.frame) - 10 - frame.origin.x;
        frame.size.height = CGRectGetHeight(self.playBtn.frame);
        frame.origin.y = self.playBtn.frame.origin.y;
        self.timeSlider.frame = frame;
    }
}

-(void)updateCurrentTime:(NSTimeInterval)time configSlider:(BOOL)configSlider {
    _currentTime = MIN(time, self.totalTime);
    self.currentTimeLb.text = [self convertTimeToString:_currentTime];
    if (configSlider) {
        if (self.totalTime > 0) {
            [self.timeSlider setValue:MIN(time * 1.0 / self.totalTime, 1) animated:YES];
        } else {
            self.timeSlider.value = 0;
        }
    }
}

-(NSString *)convertTimeToString:(NSTimeInterval)time {
    NSInteger min = time / 60;
    NSInteger sec = ((NSInteger)time) % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld",min,sec];
}

#pragma mark --- btn action ---
-(void)playBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.playBtnClicked) {
        self.playBtnClicked(sender.selected);
    }
}

-(void)sliderAction:(UISlider *)sender {
    if (self.totalTime <= 0) {
        sender.value = 0;
        return;
    }
    CGFloat time = self.totalTime * sender.value;
    [self updateCurrentTime:time configSlider:NO];
    
    if (self.sliderValueChanged) {
        self.sliderValueChanged(self.totalTime,sender.value);
    }
}

-(void)sliderTouchDownAction:(UISlider *)sender {
    if (self.sliderStatusChanged) {
        self.sliderStatusChanged(YES);
    }
}

-(void)sliderTouchUpAction:(UISlider *)sender {
    if (self.sliderStatusChanged) {
        self.sliderStatusChanged(NO);
    }
}

-(void)breakResponderChain {
    ///NOP
}

#pragma mark --- setter/getter ---
-(UIVisualEffectView *)backgroundView {
    if (!_backgroundView) {
        UIBlurEffect * effect = [UIBlurEffect effectWithStyle:(UIBlurEffectStyleDark)];
        _backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _backgroundView;
}

-(UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        UIImage * pause = [UIImage imageWithContentsOfFile:[self.imageBundle pathForResource:@"pause_control_btn@3x" ofType:@"png"]];
        [_playBtn setImage:pause forState:(UIControlStateSelected)];
        UIImage * play = [UIImage imageWithContentsOfFile:[self.imageBundle pathForResource:@"play_control_btn@3x" ofType:@"png"]];
        [_playBtn setImage:play forState:(UIControlStateNormal)];
        [_playBtn setFrame:CGRectMake(15, 0, 22, 22)];
        [_playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _playBtn;
}

-(UILabel *)currentTimeLb {
    if (!_currentTimeLb) {
        _currentTimeLb = [[UILabel alloc] init];
        _currentTimeLb.textAlignment = NSTextAlignmentRight;
        _currentTimeLb.font = [UIFont systemFontOfSize:11];
        _currentTimeLb.textColor = [UIColor whiteColor];
        [self updateCurrentTime:0];
    }
    return _currentTimeLb;
}

-(UILabel *)totalTimeLb {
    if (!_totalTimeLb) {
        _totalTimeLb = [[UILabel alloc] init];
        _totalTimeLb.font = [UIFont systemFontOfSize:11];
        _totalTimeLb.textColor = [UIColor whiteColor];
    }
    return _totalTimeLb;
}

-(UISlider *)timeSlider {
    if (!_timeSlider) {
        _timeSlider = [[UISlider alloc] init];
        _timeSlider.minimumTrackTintColor = [UIColor whiteColor];
        _timeSlider.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.3];
        [_timeSlider addTarget:self action:@selector(sliderAction:) forControlEvents:(UIControlEventValueChanged)];
        [_timeSlider addTarget:self action:@selector(sliderTouchDownAction:) forControlEvents:(UIControlEventTouchDown)];
        [_timeSlider addTarget:self action:@selector(sliderTouchUpAction:) forControlEvents:(UIControlEventTouchUpInside)];
        UIImage * thumbImage = [UIImage imageWithContentsOfFile:[self.imageBundle pathForResource:@"slider_control_pot@3x" ofType:@"png"]];
        [_timeSlider setThumbImage:thumbImage forState:(UIControlStateNormal)];
    }
    return _timeSlider;
}

-(void)setTotalTime:(NSTimeInterval)totalTime {
    if (_totalTime != totalTime) {
        _totalTime = totalTime;
        self.totalTimeLb.text = [self convertTimeToString:totalTime];
        [self setupConstraints];
    }
}

-(NSBundle *)imageBundle {
    if (!_imageBundle) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"DWMediaPreviewController" ofType:@"bundle"];
        _imageBundle = [NSBundle bundleWithPath:bundlePath];
    }
    return _imageBundle;
}

@end
