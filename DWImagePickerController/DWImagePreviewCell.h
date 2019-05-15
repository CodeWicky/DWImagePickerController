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
typedef void(^DWImagePreviewDoubleClickActionCallback)(DWImagePreviewCell * cell ,CGPoint point);
typedef void(^DWImagePreviewCellCallNavigationHideCallback)(DWImagePreviewCell * cell ,BOOL hide);

@interface DWImagePreviewCell : UICollectionViewCell

@property (nonatomic ,assign ,readonly) NSUInteger index;

@property (nonatomic ,assign) DWImagePreviewType previewType;

@property (nonatomic ,strong) id media;

@property (nonatomic ,strong) UIImage * poster;

@property (nonatomic ,assign) BOOL zoomable;

@property (nonatomic ,assign ,readonly) BOOL zooming;

@property (nonatomic ,copy) DWImagePreviewActionCallback tapAction;

@property (nonatomic ,copy) DWImagePreviewDoubleClickActionCallback doubleClickAction;

@property (nonatomic ,copy) DWImagePreviewCellCallNavigationHideCallback callNavigationHide;

-(void)resetCellZoom;

-(void)clearCell;

-(void)configGestureTarget:(UIView *)target;

///GestureAction for target view.You may implement it in subclass to do anything else.
///call the tapAction block if exist.
-(void)tapAction:(UITapGestureRecognizer *)tap;
///call the doubleClickAction block if exist.
-(void)doubleClickAction:(UITapGestureRecognizer *)doubleClick;

-(void)zoomableHasBeenChangedTo:(BOOL)zoomable;

-(void)initializingSubviews;

-(void)setupSubviews;

+(Class)classForMediaView;

-(void)configZoomScaleWithMediaSize:(CGSize)mediaSize;

-(void)zoomPosterImageView:(BOOL)zoomIn point:(CGPoint)point;

-(void)configCollectionViewController:(DWImagePreviewController *)colVC;

@end

@interface DWNormalImagePreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) UIImage * media;

@end

@interface DWAnimateImagePreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) YYImage * media;

@end

@interface DWLivePhotoPreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) PHLivePhoto * media;

@end

@interface DWVideoPreviewCell : DWImagePreviewCell

@property (nonatomic ,strong) AVPlayerItem * media;

@end

NS_ASSUME_NONNULL_END
