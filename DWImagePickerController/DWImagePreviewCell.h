//
//  DWImagePreviewCell.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWImagePreviewController.h"
#import <YYImage/YYImage.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class DWImagePreviewCell;
typedef void(^DWImagePreviewActionCallback)(DWImagePreviewCell * cell);

@interface DWImagePreviewCell : UICollectionViewCell

@property (nonatomic ,assign) DWImagePreviewType previewType;

@property (nonatomic ,strong) id media;

@property (nonatomic ,assign) BOOL zoomable;

@property (nonatomic ,copy) DWImagePreviewActionCallback tapAction;

-(void)clearCell;

-(void)zoomableHasBeenChangedTo:(BOOL)zoomable;

-(void)initializingSubviews;

@end

@interface DWNormalImagePreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) UIImage * media;

@end

@interface DWAnimateImagePreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) YYImage * media;

@end

@interface DWPhotoLivePreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) PHLivePhoto * media;

@end

@interface DWVideoPreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) AVPlayerItem * media;

@end

NS_ASSUME_NONNULL_END
