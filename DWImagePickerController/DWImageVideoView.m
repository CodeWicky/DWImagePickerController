//
//  DWImageVideoView.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/6/10.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImageVideoView.h"
#import <AVFoundation/AVFoundation.h>

static void *DWImageVideoViewPlayerItemObservationContext = &DWImageVideoViewPlayerItemObservationContext;
static void *DWImageVideoViewPlayerObservationContext = &DWImageVideoViewPlayerObservationContext;

@interface DWImageVideoView ()

@property (nonatomic ,strong) AVPlayer * player;

@property (nonatomic ,strong) AVPlayerItem * currentPlayerItem;

@property (nonatomic ,assign) DWImageVideoViewStatus status;

@property (nonatomic ,strong) AVPlayerLayer * playerLayer;

@property (nonatomic ,assign) BOOL autoPlayAfterReady;

@property (nonatomic ,assign) CGFloat rateBeforeSeeking;

@property (nonatomic ,assign) DWImageVideoViewStatus statusBeforeSeeking;

@property (nonatomic ,strong) id timeObserver;

@property (nonatomic ,assign) BOOL waitingPlayOnProcessing;

@end

@implementation DWImageVideoView
@synthesize currentPlayerItem = _currentPlayerItem;
@synthesize player = _player;
@synthesize status = _status;

#pragma mark --- interface method ---

-(BOOL)configVideoWithURL:(NSURL *)url {
    AVPlayerItem * item = [[AVPlayerItem alloc] initWithURL:url];
    return [self configVideoWithPlayerItem:item];
}

-(BOOL)configVideoWithAsset:(AVAsset *)asset {
    AVPlayerItem * item = [[AVPlayerItem alloc] initWithAsset:asset];
    return [self configVideoWithPlayerItem:item];
}

-(BOOL)configVideoWithAsset:(AVAsset *)asset automaticallyLoadedAssetKeys:(NSArray<NSString *> *)automaticallyLoadedAssetKeys {
    AVPlayerItem * item = [[AVPlayerItem alloc] initWithAsset:asset automaticallyLoadedAssetKeys:automaticallyLoadedAssetKeys];
    return [self configVideoWithPlayerItem:item];
}

-(BOOL)configVideoWithPlayerItem:(AVPlayerItem *)item {
    AVPlayerItem * oriItem = self.currentPlayerItem;
    if (![oriItem isEqual:item]) {
        ///如果URL相同则不重新播放
        if ([oriItem.asset isKindOfClass:[AVURLAsset class]] && [item.asset isKindOfClass:[AVURLAsset class]] && [((AVURLAsset *)oriItem.asset).URL isEqual:((AVURLAsset *)item.asset).URL]) {
            return NO;
        }
        
        if (oriItem) {
            [self stop];
            [self removeObserverForPlayerItem:oriItem];
        }
        
        _currentPlayerItem = item;
        [self.player replaceCurrentItemWithPlayerItem:item];
        [self addObserverForPlayerItem:item];
        self.status = DWImageVideoViewProcessing;
        _waitingPlayOnProcessing = NO;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:didChangePlayerItemTo:fromItem:)]) {
            [self.delegate videoView:self didChangePlayerItemTo:item fromItem:oriItem];
        }
        return YES;
    }
    return NO;
}

-(void)play {
    switch (self.status) {
        case DWImageVideoViewUnknown:
        case DWImageVideoViewFailed:
        case DWImageVideoViewPlaying:
        case DWImageVideoViewSeekingProgress:
        {
            return;
        }
            break;
        case DWImageVideoViewProcessing:
        {
            self.waitingPlayOnProcessing = YES;
            return;
        }
            break;
        case DWImageVideoViewFinished:
        {
            ///此处不写break是为了把事件透过去
            [self.player seekToTime:kCMTimeZero];
        }
        default:
        {
            self.status = DWImageVideoViewPlaying;
            [self.player play];
        }
            break;
    }
}

-(void)pause {
    if (self.status == DWImageVideoViewPlaying) {
        self.status = DWImageVideoViewPaused;
        [self.player pause];
    }
}

-(void)stop {
    if (self.status == DWImageVideoViewPlaying || self.status == DWImageVideoViewPaused) {
        self.status = DWImageVideoViewReadyToPlay;
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
    }
}

-(void)replay {
    switch (self.status) {
        ///暂停及完成需要重置时间并开始播放
        case DWImageVideoViewPaused:
        case DWImageVideoViewFinished:
        {
            ///这里不写break是为了将事件穿透
            [self.player seekToTime:kCMTimeZero];
        }
        ///ready直接开始播放即可
        case DWImageVideoViewReadyToPlay:
        {
            ///更改状态并开始播放
            self.status = DWImageVideoViewPlaying;
            [self.player play];
        }
            break;
        ///playing则只需要重置时间
        case DWImageVideoViewPlaying:
        {
            ///重置时间
            [self.player seekToTime:kCMTimeZero];
        }
            break;
        ///其他状态均为不合法状态，不作处理
        default:
            break;
    }
}

-(void)seekToTime:(CGFloat)time completionHandler:(void (^)(BOOL))completionHandler {
    DWImageVideoViewStatus status = self.status;
    if (status == DWImageVideoViewUnknown || status == DWImageVideoViewFailed || status == DWImageVideoViewSeekingProgress) {
        return;
    }
    self.status = DWImageVideoViewSeekingProgress;
    [self removeTimeObserverForPlayer];
    _rateBeforeSeeking = self.player.rate;
    self.player.rate = 0;
    __weak typeof(self)weakSelf = self;
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        [weakSelf addTimeObserverForPlayer];
        weakSelf.status = status;
        weakSelf.player.rate = weakSelf.rateBeforeSeeking;
        weakSelf.rateBeforeSeeking = 1;
        [weakSelf seekToTimeCallback];
        if (completionHandler) {
            completionHandler(finished);
        }
    }];
}

-(void)beginSeekingTime {
    DWImageVideoViewStatus status = self.status;
    if (status == DWImageVideoViewUnknown || status == DWImageVideoViewFailed || status == DWImageVideoViewSeekingProgress) {
        return;
    }
    self.status = DWImageVideoViewSeekingProgress;
    [self removeTimeObserverForPlayer];
    _rateBeforeSeeking = self.player.rate;
    _statusBeforeSeeking = status;
    self.player.rate = 0;
}

-(void)seekToTimeContinuously:(CGFloat)time completionHandler:(void (^)(BOOL))completionHandler {
    if (self.status == DWImageVideoViewSeekingProgress) {
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:completionHandler];
        [self seekToTimeCallback];
    }
}

-(void)endSeekingTime {
    if (self.status == DWImageVideoViewSeekingProgress) {
        [self addTimeObserverForPlayer];
        self.status = self.statusBeforeSeeking;
        self.statusBeforeSeeking = DWImageVideoViewUnknown;
        self.player.rate = self.rateBeforeSeeking;
        self.rateBeforeSeeking = 1;
    }
}

-(NSTimeInterval)convertCMTimeToTimeInterval:(CMTime)time {
    return CMTimeGetSeconds(time);
}

-(CMTime)actualTimeForItem:(AVPlayerItem *)item {
    if ([item.asset isKindOfClass:[AVURLAsset class]]) {
        NSURL * url = ((AVURLAsset *)item.asset).URL;
        NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts]; // 初始化视频媒体文件
        return urlAsset.duration;
    } else {
        return item.duration;
    }
}

#pragma mark --- KVO ---
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == DWImageVideoViewPlayerItemObservationContext) {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerItemStatusFailed:
                {
                    self.status = DWImageVideoViewFailed;
                }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
                    self.status = DWImageVideoViewReadyToPlay;
                    if ([object isKindOfClass:[AVPlayerItem class]]) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:readyToPlayForItem:)]) {
                            [self.delegate videoView:self readyToPlayForItem:object];
                        }
                    }
                    if (self.waitingPlayOnProcessing) {
                        self.waitingPlayOnProcessing = NO;
                        [self play];
                    }
                }
                    break;
                default:
                {
                    self.status = DWImageVideoViewUnknown;
                }
                    break;
            }
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            if ([object isKindOfClass:[AVPlayerItem class]] && ((AVPlayerItem *)object).playbackBufferEmpty) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:playbackBufferStatusChanged:forItem:)]) {
                    [self.delegate videoView:self playbackBufferStatusChanged:YES forItem:object];
                }
            }
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            if ([object isKindOfClass:[AVPlayerItem class]] && ((AVPlayerItem *)object).playbackLikelyToKeepUp) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:playbackBufferStatusChanged:forItem:)]) {
                    [self.delegate videoView:self playbackBufferStatusChanged:NO forItem:object];
                }
            }
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            if ([object isKindOfClass:[AVPlayerItem class]] && ((AVPlayerItem *)object).loadedTimeRanges) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:loadedTimeRangesChangedTo:forItem:)]) {
                    [self.delegate videoView:self loadedTimeRangesChangedTo:((AVPlayerItem *)object).loadedTimeRanges forItem:(AVPlayerItem *)object];
                }
            }
        }
    }
}

#pragma mark --- Notification ---
-(void)playerItemDidReachEnd:(NSNotification *)sender {
    if ([sender.object isEqual:self.currentPlayerItem]) {
        self.status = DWImageVideoViewFinished;
    }
}

#pragma mark --- tool method ---
-(void)addTimeObserverForPlayer {
    if (!self.timeObserver) {
        __weak typeof(self)weakSelf = self;
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(self.timeIntervalForPlayerTimeObserver, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            [weakSelf playerTimeChangerCallback:time];
        }];
    }
}

-(void)removeTimeObserverForPlayer {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

-(void)playerTimeChangerCallback:(CMTime)time {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:playerTimeChangeTo:forItem:)]) {
        [self.delegate videoView:self playerTimeChangeTo:time forItem:self.currentPlayerItem];
    }
}

-(void)addObserverForPlayerItem:(AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWImageVideoViewPlayerItemObservationContext];
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWImageVideoViewPlayerItemObservationContext];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWImageVideoViewPlayerItemObservationContext];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWImageVideoViewPlayerItemObservationContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
}

-(void)removeObserverForPlayerItem:(AVPlayerItem *)item {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

-(void)seekToTimeCallback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:seekToTime:forItem:)]) {
        [self.delegate videoView:self seekToTime:self.currentPlayerItem.currentTime forItem:self.currentPlayerItem];
    }
}

#pragma mark --- override ---
+(Class)layerClass {
    return [AVPlayerLayer class];
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _status = DWImageVideoViewUnknown;
        _timeIntervalForPlayerTimeObserver = 0.5;
        _autoPlayAfterReady = NO;
        _rateBeforeSeeking = 0;
        _statusBeforeSeeking = DWImageVideoViewUnknown;
    }
    return self;
}

#pragma mark --- setter/getter ---
-(void)setStatus:(DWImageVideoViewStatus)status {
    if (_status != status) {
        [self willChangeValueForKey:@"status"];
        DWImageVideoViewStatus oriStatus = _status;
        _status = status;
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:didChangeStatusTo:fromStatus:forItem:)]) {
            [self.delegate videoView:self didChangeStatusTo:status fromStatus:oriStatus forItem:self.currentPlayerItem];
        }
        [self didChangeValueForKey:@"status"];
    }
}

-(void)setTimeIntervalForPlayerTimeObserver:(NSTimeInterval)timeIntervalForPlayerTimeObserver {
    if (_timeIntervalForPlayerTimeObserver != timeIntervalForPlayerTimeObserver) {
        _timeIntervalForPlayerTimeObserver = timeIntervalForPlayerTimeObserver;
        [self removeTimeObserverForPlayer];
        [self addTimeObserverForPlayer];
    }
}

-(void)setResizeMode:(DWImageVideoResizeMode)resizeMode {
    if (_resizeMode != resizeMode) {
        _resizeMode = resizeMode;
        switch (resizeMode) {
            case DWImageVideoResizeModeScaleToFill:
            {
                self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            }
                break;
            case DWImageVideoResizeModeScaleAspectFill:
            {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            }
                break;
            default:
            {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            }
                break;
        }
    }
}

-(void)setRate:(CGFloat)rate {
    if (_rate != rate) {
        _rate = rate;
        self.player.rate = rate;
    }
}

-(AVPlayerItem *)currentPlayerItem {
    return self.player.currentItem;
}

-(AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:nil];
        [self.playerLayer setPlayer:_player];
    }
    return _player;
}

-(AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end
