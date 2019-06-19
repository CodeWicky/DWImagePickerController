//
//  DWMediaPreviewCell.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWMediaPreviewController.h"
#import <YYImage/YYImage.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>


NS_ASSUME_NONNULL_BEGIN

@class DWMediaPreviewCell;
typedef void(^DWMediaPreviewActionCallback)(DWMediaPreviewCell * cell);
typedef void(^DWMediaPreviewDoubleClickActionCallback)(DWMediaPreviewCell * cell ,CGPoint point);
typedef void(^DWMediaPreviewCellCallNavigationHideCallback)(DWMediaPreviewCell * cell ,BOOL hide);

//DWMediaPreviewCell is a abstract class of DWMediaPreviewController displaying unit.It provide some basic method to help you customize your preview cell by them or override them.
///DWMediaPreviewCell是DWMediaPreviewController展示单元的一个抽象类。提供了一些基础方法，通过他们，你可以在你定制的cell中直接调用这些基础方法，或者重写他们来满足你的需求。
@interface DWMediaPreviewCell : UICollectionViewCell

//The current index for what the cell is displaying.For is an asynchous process when fetching media,callback may be called after the current diplaying has changed.Use index to determine whether to set media.
///当前cell正在展示对应的角标。获取媒体的过程是异步的，可能会发生当前要展示的资源已经改变了资源才获取完成的情况。此时可以通过index来决定是否要设置媒体。
@property (nonatomic ,assign ,readonly) NSUInteger index;

//Indicates the preview type of current media.
///当前正在展示的媒体的预览类型
@property (nonatomic ,assign) DWMediaPreviewType previewType;

//The media current displaying.
///当前正在展示的媒体。
@property (nonatomic ,strong) id media;

//The poster for current media.Cell will show poster before finish fetching media.
///当前要展示的媒体的缩略图，在媒体资源获取完成之前，会优先展示缩略图。
@property (nonatomic ,strong) UIImage * poster;

//Indicates whether the preview cell can zoom its media.Default by YES.
///当前cell是否可以缩放显示其展示的媒体。默认支持缩放。
@property (nonatomic ,assign) BOOL zoomable;

//Indicates whether the media is zooming.
///表明当前媒体是否正处于缩放状态。
@property (nonatomic ,assign ,readonly) BOOL zooming;

//Indicates whether the media is an hdr type.If YES there will be a hdr badge on preview cell.
///表明当前展示的资源是否是hdr类型。如果是的话，将会在cell上展示一个hdr的角标。
@property (nonatomic ,assign) BOOL isHDR;

//Callback for tapAction on previewCell.
///在单点cell时会触发的回调。
@property (nonatomic ,copy) DWMediaPreviewActionCallback tapAction;

//Callback for doubleClickAction on previewCell.
///在cell上双击时会触发的回调。
@property (nonatomic ,copy) DWMediaPreviewDoubleClickActionCallback doubleClickAction;

//Callback for previewCell to call DWMediaPreviewController to hide navigationBar.It will be call on cell zooming.And you can call it where you want in you subclass to hide navigationBar and do something else at the same time.
///当cell通知DWMediaPreviewController隐藏导航栏时触发的回调。当缩放媒体的时候回触发此回调。你也可以在子类中按照你的需求在合适的实际调用他去隐藏导航栏，同时你也可以做一些其他的事情。
@property (nonatomic ,copy) DWMediaPreviewCellCallNavigationHideCallback callNavigationHide;

#pragma mark --- interface method ---

//For now the cell has the same size as collectionView,so you could only see one cell at most at a time.It consider to resign the focus when the cell leave the viewport,then the other cell which is being shown getFocus.Then with these two follow method you can do something you want when the focus changed.They will be called automatically on -collectionView:didEndDisplayingCell:forItemAtIndexPath: .
///当前整体的设计形式中，预览控制器同时只能展示一个资源。所以当当前展示的资源彻底离开视口的时候，我们认为他释放了焦点，同时视口中正在展示的资源获取了焦点。所以借助这两个方法你可以在焦点状态改变时定制具体的行为。这两个方法会在 -collectionView:didEndDisplayingCell:forItemAtIndexPath: 中自动调用。
-(void)resignFocus;
-(void)getFocus;

//Clear the preview cell all status to origin status.You may call it when you want to do so,and it will be called automatically on -prepareForReuse .
///清除cell当前状态及相关展示的方法。你可以随时调用他，同时系统将会在 -prepareForReuse 时自动调用他。
-(void)clearCell NS_REQUIRES_SUPER;

//Zoom the preview view for media at specific point.
///以指定点为中心缩放当前媒体。
-(void)zoomMediaView:(BOOL)zoomIn point:(CGPoint)point;

//Config the preview cell with previewController so that preview cell can handle something itself via previewController.You should always call it when you config the preview cell.
///给cell配置他对应的预览控制器，这样cell才可以根据他来处理相关布局问题。如果你重写了DWMediaPreviewController，在cellForItem代理中必须调用此方法。
-(void)configCollectionViewController:(DWMediaPreviewController *)colVC NS_REQUIRES_SUPER;
#pragma mark --- call back method ---
//These methods below are call back for different event.They maybe called on specific event automatically.Override it if you have other things to do on it.
///以下方法都是一些预制的钩子方法，在特定的事件中会自动调用一下方法。你可以重写这些方法来定制化你的cell。

//Indicates the container view for media.For example,you may return +[UIImageView class] for a normal image, as well as +[YYImageView class] for an animated image.called on -initializingSubviews;
///表明当前展示的媒体使用的视图类型。例如，当展示一个普通图片时，你仅需返回 +[UIImageView class] 即可，此时会以一个UIImageView来展示图片。如果你要展示的是一个动态图片，你可以在此处返回 +[YYImageView class]。这时媒体的容器则会变为YYImageView。这个方法会在 -initializingSubviews 中调用。
+(Class)classForMediaView;

//Initialize subviews on first time calling -layoutSubviews.
///初始化一些子视图资源，会在cell首次调用 -layoutSubviews 时自动调用。
-(void)initializingSubviews;

//Setup subviews on calling -layoutSubviews.
///配置子视图的回调方法，每次调用 -layoutSubviews 时都会调用。
-(void)setupSubviews;

//Indicates the size for media in order to config scale factor,called on -setMedia: .
///表明当前资源的实际尺寸。这个尺寸将用来配置缩放参数。在 -setMedia: 时会调用此方法。
-(CGSize)sizeForMedia:(id)media;

//Calculate the media factor in preview cell.It will be called on -setMedia: .Besides,if the preview cell is zoomable and the cell frame has been changed,it will also be called on -setupSubviews.
///当需要计算缩放比例时会自动调用，其中mediaSize即为当前展示的资源的实际尺寸。在-setMedia: 时会调用此方法。此外，如果当前cell是可缩放的且他的frame发生改变时，在下一次 -setupSubviews 中也会调用此方法。
-(void)configScaleFactorWithMediaSize:(CGSize)mediaSize;

//Config the badge such as HDR and livephoto for cell.It will be called on -setMedia: and -setupSubviews.
///配置当前资源的角标视图。在 -setMedia: 及 -setupSubviews 中会调用此方法。
-(void)configBadgeWithAnimated:(BOOL)animated;

//Call back for reset cell zoom status,called on -clearCell.
///重置当前cell的一些状态信息。在 -clearCell 中会调用。
-(void)resetCellZoom;

//Call back for zoomableStatus has been changed,called on -setZoomable:
///当是否可缩放能力改变时会调用，即 -setZoomable 中调用。
-(void)zoomableHasBeenChangedTo:(BOOL)zoomable;

//GestureAction for target view.You may implement it in subclass to do anything else.
///当前cell上一些手势事件的回调。

//Callback on tapAction. Call the tapAction block if exist by default.
///单点手势的事件。默认会调用 tapAction 回调。
-(void)tapAction:(UITapGestureRecognizer *)tap;

//Callback on doubleClickAction. Call the doubleClickAction block if exist by default.
///双击手势的事件。默认会调用 doubleClickAction 回调。
-(void)doubleClickAction:(UITapGestureRecognizer *)doubleClick;

@end

//Cell to display normal image.
///展示普通UIImage的cell
@interface DWNormalImagePreviewCell : DWMediaPreviewCell

@property (nonatomic ,strong) UIImage * media;

@end

//Cell to display animate image.
///展示动态图片的cell
@interface DWAnimateImagePreviewCell : DWMediaPreviewCell

@property (nonatomic ,strong) YYImage * media;

@end

//Cell to display livephoto.
///展示LivePhoto的cell
@interface DWLivePhotoPreviewCell : DWMediaPreviewCell

@property (nonatomic ,strong) PHLivePhoto * media;

@end

//Cell to display video.
///展示视频的cell
@interface DWVideoPreviewCell : DWMediaPreviewCell

@property (nonatomic ,strong) AVPlayerItem * media;

@end

NS_ASSUME_NONNULL_END
