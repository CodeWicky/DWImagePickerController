//
//  DWMediaPreviewVideoView.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/6/10.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWMediaPreviewVideoView.h"
#import <AVFoundation/AVFoundation.h>

static void *DWMediaPreviewVideoViewPlayerItemObservationContext = &DWMediaPreviewVideoViewPlayerItemObservationContext;
static void *DWMediaPreviewVideoViewPlayerObservationContext = &DWMediaPreviewVideoViewPlayerObservationContext;

@interface DWMediaPreviewVideoView ()

@property (nonatomic ,strong) AVPlayer * player;

@property (nonatomic ,strong) AVAsset * currentAsset;

@property (nonatomic ,strong) AVPlayerItem * currentPlayerItem;

@property (nonatomic ,assign) DWMediaPreviewVideoViewStatus status;

@property (nonatomic ,strong) AVPlayerLayer * playerLayer;

@property (nonatomic ,assign) BOOL autoPlayAfterReady;

@property (nonatomic ,assign) CGFloat rateBeforeSeeking;

@property (nonatomic ,assign) DWMediaPreviewVideoViewStatus statusBeforeSeeking;

@property (nonatomic ,strong) id timeObserver;

@property (nonatomic ,assign) BOOL waitingPlayOnProcessing;

@end

@implementation DWMediaPreviewVideoView
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
    ///这里由于同一个AVPlayerItem不能赋给不同的AVPlayer对象，而当给 -[AVPlayer replaceCurrentItemWithPlayerItem:] 时，虽然解除了AVPlayer对AVPlayerItem的绑定关系，但是并不能接触AVPlayerItem对AVPlayer的绑定关系。导致下一次相同AVPlayerItem绑定至不同AVPlayer时崩溃的现象。所以在应确保外界替换视频源时，务必替换AVPlayerItem。这里框架内部采用每次生成一个新的item来保证item不会重新使用。
    if (![self.currentPlayerItem isEqual:item]) {
        ///如果URL相同则不重新播放
        if ([self.currentAsset isKindOfClass:[AVURLAsset class]] && [item.asset isKindOfClass:[AVURLAsset class]] && [((AVURLAsset *)self.currentAsset).URL isEqual:((AVURLAsset *)item.asset).URL]) {
            return NO;
        }
        
        if (self.currentPlayerItem) {
            [self stop];
            [self removeObserverForPlayerItem:self.currentPlayerItem];
        }
        AVAsset * oriAsset = self.currentAsset;
        _currentAsset = item.asset;
        self.status = DWMediaPreviewVideoViewUnknown;
        [self.player replaceCurrentItemWithPlayerItem:item];
        if (item) {
            [self addObserverForPlayerItem:item];
            self.status = DWMediaPreviewVideoViewProcessing;
        }
        
        _waitingPlayOnProcessing = NO;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:didChangeAssetTo:fromAsset:)]) {
            [self.delegate videoView:self didChangeAssetTo:oriAsset fromAsset:self.currentAsset];
        }
        return YES;
    }
    return NO;
}

-(void)play {
    switch (self.status) {
        case DWMediaPreviewVideoViewUnknown:
        case DWMediaPreviewVideoViewFailed:
        case DWMediaPreviewVideoViewPlaying:
        case DWMediaPreviewVideoViewSeekingProgress:
        {
            return;
        }
            break;
        case DWMediaPreviewVideoViewProcessing:
        {
            self.waitingPlayOnProcessing = YES;
            return;
        }
            break;
        case DWMediaPreviewVideoViewFinished:
        {
            ///此处不写break是为了把事件透过去
            [self.player seekToTime:kCMTimeZero];
        }
        default:
        {
            self.status = DWMediaPreviewVideoViewPlaying;
            [self.player play];
        }
            break;
    }
}

-(void)pause {
    if (self.status == DWMediaPreviewVideoViewPlaying) {
        self.status = DWMediaPreviewVideoViewPaused;
        [self.player pause];
    }
}

-(void)stop {
    if (self.status == DWMediaPreviewVideoViewPlaying || self.status == DWMediaPreviewVideoViewPaused) {
        self.status = DWMediaPreviewVideoViewReadyToPlay;
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
    }
}

-(void)replay {
    switch (self.status) {
        ///暂停及完成需要重置时间并开始播放
        case DWMediaPreviewVideoViewPaused:
        case DWMediaPreviewVideoViewFinished:
        {
            ///这里不写break是为了将事件穿透
            [self.player seekToTime:kCMTimeZero];
        }
        ///ready直接开始播放即可
        case DWMediaPreviewVideoViewReadyToPlay:
        {
            ///更改状态并开始播放
            self.status = DWMediaPreviewVideoViewPlaying;
            [self.player play];
        }
            break;
        ///playing则只需要重置时间
        case DWMediaPreviewVideoViewPlaying:
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
    DWMediaPreviewVideoViewStatus status = self.status;
    if (status == DWMediaPreviewVideoViewUnknown || status == DWMediaPreviewVideoViewFailed || status == DWMediaPreviewVideoViewSeekingProgress) {
        return;
    }
    self.status = DWMediaPreviewVideoViewSeekingProgress;
    [self removeTimeObserverForPlayer];
    _rateBeforeSeeking = self.player.rate;
    self.player.rate = 0;
    __weak typeof(self)weakSelf = self;
    CMTime cmTime = CMTimeMakeWithSeconds(time, NSEC_PER_SEC);
    [self.player seekToTime:cmTime completionHandler:^(BOOL finished) {
        [weakSelf addTimeObserverForPlayer];
        weakSelf.status = status;
        weakSelf.player.rate = weakSelf.rateBeforeSeeking;
        weakSelf.rateBeforeSeeking = 1;
        [weakSelf seekToTimeCallback:cmTime];
        if (completionHandler) {
            completionHandler(finished);
        }
    }];
}

-(void)beginSeekingTime {
    DWMediaPreviewVideoViewStatus status = self.status;
    if (status == DWMediaPreviewVideoViewUnknown || status == DWMediaPreviewVideoViewFailed || status == DWMediaPreviewVideoViewSeekingProgress) {
        return;
    }
    self.status = DWMediaPreviewVideoViewSeekingProgress;
    [self removeTimeObserverForPlayer];
    _rateBeforeSeeking = self.player.rate;
    _statusBeforeSeeking = status;
    self.player.rate = 0;
}

-(void)seekToTimeContinuously:(CGFloat)time completionHandler:(void (^)(BOOL))completionHandler {
    if (self.status == DWMediaPreviewVideoViewSeekingProgress) {
        CMTime cmTime = CMTimeMakeWithSeconds(time, NSEC_PER_SEC);
        [self.player seekToTime:cmTime completionHandler:completionHandler];
        [self seekToTimeCallback:cmTime];
    }
}

-(void)endSeekingTime {
    if (self.status == DWMediaPreviewVideoViewSeekingProgress) {
        [self addTimeObserverForPlayer];
        self.status = self.statusBeforeSeeking;
        self.statusBeforeSeeking = DWMediaPreviewVideoViewUnknown;
        self.player.rate = self.rateBeforeSeeking;
        self.rateBeforeSeeking = 1;
    }
}

-(NSTimeInterval)convertCMTimeToTimeInterval:(CMTime)time {
    return CMTimeGetSeconds(time);
}

-(CMTime)actualTimeForAsset:(AVAsset *)asset {
    if ([asset isKindOfClass:[AVURLAsset class]]) {
        NSURL * url = ((AVURLAsset *)asset).URL;
        NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts]; // 初始化视频媒体文件
        return urlAsset.duration;
    } else {
        return asset.duration;
    }
}

#pragma mark --- KVO ---
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == DWMediaPreviewVideoViewPlayerItemObservationContext) {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerItemStatusFailed:
                {
                    self.status = DWMediaPreviewVideoViewFailed;
                }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
                    self.status = DWMediaPreviewVideoViewReadyToPlay;
                    if ([object isKindOfClass:[AVPlayerItem class]]) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:readyToPlayForAsset:)]) {
                            [self.delegate videoView:self readyToPlayForAsset:((AVPlayerItem *)object).asset];
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
                    self.status = DWMediaPreviewVideoViewUnknown;
                }
                    break;
            }
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            if ([object isKindOfClass:[AVPlayerItem class]] && ((AVPlayerItem *)object).playbackBufferEmpty) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:playbackBufferStatusChanged:forAsset:)]) {
                    [self.delegate videoView:self playbackBufferStatusChanged:YES forAsset:((AVPlayerItem *)object).asset];
                }
            }
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            if ([object isKindOfClass:[AVPlayerItem class]] && ((AVPlayerItem *)object).playbackLikelyToKeepUp) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:playbackBufferStatusChanged:forAsset:)]) {
                    [self.delegate videoView:self playbackBufferStatusChanged:NO forAsset:((AVPlayerItem *)object).asset];
                }
            }
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            if ([object isKindOfClass:[AVPlayerItem class]] && ((AVPlayerItem *)object).loadedTimeRanges) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:loadedTimeRangesChangedTo:forAsset:)]) {
                    [self.delegate videoView:self loadedTimeRangesChangedTo:((AVPlayerItem *)object).loadedTimeRanges forAsset:((AVPlayerItem *)object).asset];
                }
            }
        }
    }
}

#pragma mark --- Notification ---
-(void)playerItemDidReachEnd:(NSNotification *)sender {
    if ([sender.object isKindOfClass:[AVPlayerItem class]] && [((AVPlayerItem *)sender.object).asset isEqual:self.currentAsset]) {
        self.status = DWMediaPreviewVideoViewFinished;
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:finishPlayingAsset:)]) {
            [self.delegate videoView:self finishPlayingAsset:((AVPlayerItem *)sender.object).asset];
        }
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:playerTimeChangeTo:forAsset:)]) {
        [self.delegate videoView:self playerTimeChangeTo:time forAsset:self.currentAsset];
    }
}

-(void)addObserverForPlayerItem:(AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWMediaPreviewVideoViewPlayerItemObservationContext];
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWMediaPreviewVideoViewPlayerItemObservationContext];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWMediaPreviewVideoViewPlayerItemObservationContext];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:DWMediaPreviewVideoViewPlayerItemObservationContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
}

-(void)removeObserverForPlayerItem:(AVPlayerItem *)item {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:item];
}

-(void)seekToTimeCallback:(CMTime)time {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:seekToTime:forAsset:)]) {
        [self.delegate videoView:self seekToTime:time forAsset:self.currentAsset];
    }
}

#pragma mark --- override ---
+(Class)layerClass {
    return [AVPlayerLayer class];
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _status = DWMediaPreviewVideoViewUnknown;
        _timeIntervalForPlayerTimeObserver = 0.5;
        _autoPlayAfterReady = NO;
        _rateBeforeSeeking = 0;
        _statusBeforeSeeking = DWMediaPreviewVideoViewUnknown;
    }
    return self;
}

#pragma mark --- setter/getter ---
-(void)setStatus:(DWMediaPreviewVideoViewStatus)status {
    if (_status != status) {
        [self willChangeValueForKey:@"status"];
        DWMediaPreviewVideoViewStatus oriStatus = _status;
        _status = status;
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoView:didChangeStatusTo:fromStatus:forAsset:)]) {
            [self.delegate videoView:self didChangeStatusTo:status fromStatus:oriStatus forAsset:self.currentAsset];
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
