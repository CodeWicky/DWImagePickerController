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

@property (nonatomic ,assign) BOOL isHDR;

@property (nonatomic ,copy) DWImagePreviewActionCallback tapAction;

@property (nonatomic ,copy) DWImagePreviewDoubleClickActionCallback doubleClickAction;

@property (nonatomic ,copy) DWImagePreviewCellCallNavigationHideCallback callNavigationHide;

#pragma mark --- interface method ---
///Clear the preview cell all status to origin status.You may call it when you want to do so,and it will be called automatically on -prepareForReuse .
-(void)clearCell;
///Zoom the preview view for media at specific point.
-(void)zoomMediaView:(BOOL)zoomIn point:(CGPoint)point;
///Config the preview cell with previewController so that preview cell can handle something itself via previewController.You should always call it when you config the preview cell.
-(void)configCollectionViewController:(DWImagePreviewController *)colVC;
#pragma mark --- call back method ---
///These methods below are call back for different event.They maybe called on specific event automatically.Override it if you have other things to do on it.

///Indicates the container view for media.For example,you may return +[UIImageView class] for a normal image, as well as +[YYImageView class] for an animated image.called on -initializingSubviews;
+(Class)classForMediaView;
///Initialize subviews on first time calling -layoutSubviews.
-(void)initializingSubviews;
///Setup subviews on calling -layoutSubviews.
-(void)setupSubviews;
///Indicates the size for media in order to config scale factor,called on -setMedia: .
-(CGSize)sizeForMedia:(id)media;
///Calculate the media factor in preview cell.It will be called on -setMedia: .Besides,if the preview cell is zoomable and the cell frame has been changed,it will also be called on -setupSubviews.
-(void)configScaleFactorWithMediaSize:(CGSize)mediaSize;
///Config the badge such as HDR and livephoto for cell.It will be called on -setMedia: and -setupSubviews.
-(void)configBadgeWithAnimated:(BOOL)animated;
///Call back for reset cell zoom status,called on -clearCell.
-(void)resetCellZoom;
///Call back for zoomableStatus has been changed,called on -setZoomable:
-(void)zoomableHasBeenChangedTo:(BOOL)zoomable;
///GestureAction for target view.You may implement it in subclass to do anything else.
///call the tapAction block if exist.
-(void)tapAction:(UITapGestureRecognizer *)tap;
///call the doubleClickAction block if exist.
-(void)doubleClickAction:(UITapGestureRecognizer *)doubleClick;

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
