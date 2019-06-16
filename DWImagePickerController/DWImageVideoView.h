//
//  DWImageVideoView.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/6/10.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, DWImageVideoViewStatus) {
    DWImageVideoViewUnknown,
    DWImageVideoViewProcessing,
    DWImageVideoViewReadyToPlay,
    DWImageVideoViewPlaying,
    DWImageVideoViewSeekingProgress,
    DWImageVideoViewPaused,
    DWImageVideoViewFinished,
    DWImageVideoViewFailed,
};

typedef NS_ENUM(NSUInteger, DWImageVideoResizeMode) {
    DWImageVideoResizeModeScaleAspectFit,
    DWImageVideoResizeModeScaleAspectFill,
    DWImageVideoResizeModeScaleToFill,
};

@class DWImageVideoView;
@protocol DWImageVideoViewProtocol <NSObject>
@optional
-(void)videoView:(DWImageVideoView *)videoView didChangeAssetTo:(AVAsset *)desAsset fromAsset:(AVAsset *)oriAsset;

-(void)videoView:(DWImageVideoView *)videoView readyToPlayForAsset:(AVAsset *)asset;

-(void)videoView:(DWImageVideoView *)videoView seekToTime:(CMTime)time forAsset:(AVAsset *)asset;

-(void)videoView:(DWImageVideoView *)videoView playbackBufferStatusChanged:(BOOL)empty forAsset:(AVAsset *)asset;

-(void)videoView:(DWImageVideoView *)videoView loadedTimeRangesChangedTo:(NSArray <NSValue *>*)timeRanges forAsset:(AVAsset *)asset;

-(void)videoView:(DWImageVideoView *)videoView didChangeStatusTo:(DWImageVideoViewStatus)desStatus fromStatus:(DWImageVideoViewStatus)oriStatus forAsset:(AVAsset *)asset;

-(void)videoView:(DWImageVideoView *)videoView playerTimeChangeTo:(CMTime)time forAsset:(AVAsset *)asset;

-(void)videoView:(DWImageVideoView *)videoView finishPlayingAsset:(AVAsset *)asset;

@end

@interface DWImageVideoView : UIView

@property (nonatomic ,weak) id<DWImageVideoViewProtocol> delegate;

@property (nonatomic ,strong ,readonly) AVPlayer * player;

@property (nonatomic ,strong ,readonly) AVAsset * currentAsset;

@property (nonatomic ,assign ,readonly) DWImageVideoViewStatus status;

@property (nonatomic ,assign) DWImageVideoResizeMode resizeMode;

@property (nonatomic ,assign) NSTimeInterval timeIntervalForPlayerTimeObserver;

@property (nonatomic ,assign) CGFloat rate;

-(BOOL)configVideoWithURL:(NSURL *)url;

-(BOOL)configVideoWithAsset:(AVAsset *)asset;

-(BOOL)configVideoWithAsset:(AVAsset *)asset automaticallyLoadedAssetKeys:(NSArray<NSString *> *)automaticallyLoadedAssetKeys NS_AVAILABLE(10_9, 7_0);

-(void)play;

-(void)pause;

-(void)stop;

-(void)replay;

-(void)seekToTime:(CGFloat)time completionHandler:(void (^)(BOOL))completionHandler;

-(void)beginSeekingTime;
-(void)seekToTimeContinuously:(CGFloat)time completionHandler:(void (^)(BOOL))completionHandler;
-(void)endSeekingTime;

-(NSTimeInterval)convertCMTimeToTimeInterval:(CMTime)time;

-(CMTime)actualTimeForAsset:(AVAsset *)asset;

@end
