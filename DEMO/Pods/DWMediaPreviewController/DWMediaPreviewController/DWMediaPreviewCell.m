//
//  DWMediaPreviewCell.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWMediaPreviewCell.h"
#import <PhotosUI/PhotosUI.h>
#import <DWPlayer/DWPlayerView.h>
#import "DWMediaPreviewVideoControl.h"
#import "DWMediaPreviewLoading.h"

#define CGFLOATEQUAL(a,b) (fabs(a - b) <= __FLT_EPSILON__)

typedef NS_ENUM(NSUInteger, DWMediaPreviewZoomType) {
    DWMediaPreviewZoomTypeNone,
    DWMediaPreviewZoomTypeHorizontal,
    DWMediaPreviewZoomTypeVertical,
};

typedef NS_ENUM(NSUInteger, DWImagePanDirectionType) {
    DWImagePanDirectionTypeNone,
    DWImagePanDirectionTypeHorizontal,
    DWImagePanDirectionTypeVertical,
};

@interface DWMediaPreviewCell ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>
{
    BOOL _finishInitializingLayout;
}

@property (nonatomic ,strong) UIView * containerView;

@property (nonatomic ,strong) UIScrollView * zoomContainerView;

@property (nonatomic ,strong) UIImageView * mediaView;

@property (nonatomic ,strong) UIImageView * hdrBadge;

@property (nonatomic ,assign) CGSize mediaSize;

@property (nonatomic ,assign) DWMediaPreviewZoomType zoomDirection;

@property (nonatomic ,assign) BOOL scrollIsZooming;

@property (nonatomic ,assign) CGFloat preferredZoomScale;

@property (nonatomic ,assign) CGFloat fixStartAnchor;

@property (nonatomic ,assign) CGFloat fixEndAnchor;

@property (nonatomic ,strong) UIPanGestureRecognizer * panGes;

@property (nonatomic ,assign) DWImagePanDirectionType panDirection;

@property (nonatomic ,weak) DWMediaPreviewController * previewController;

@property (nonatomic ,strong) NSBundle * imageBundle;

@end

@implementation DWMediaPreviewCell

#pragma mark --- interface method ---
-(void)resignFocus {
    ///Nothing to do with normal cell.
}

-(void)getFocus {
    ///Nothing to do with normal cell.
}

-(void)clearCell {
    [self resetCellZoom];
    _panDirection = DWImagePanDirectionTypeNone;
    _media = nil;
    _mediaSize = CGSizeZero;
    _isHDR = NO;
    _hdrBadge.alpha = 0;
}

-(void)zoomMediaView:(BOOL)zoomIn point:(CGPoint)point {
    if (self.zoomable) {
        UIScrollView *scrollView = (UIScrollView *)self.containerView;
        if (!CGRectContainsPoint(self.mediaView.bounds, point)) {
            return;
        }
        if (!zoomIn) {
            [scrollView setZoomScale:1 animated:YES];
        } else {
            switch (self.zoomDirection) {
                case DWMediaPreviewZoomTypeHorizontal:
                {
                    ///缩放至指定位置（origin 指定的是期待缩放以后屏幕中心的位置，size展示在屏幕上全屏尺寸对应的原始尺寸，会取较小的值作为缩放比）
                    [scrollView zoomToRect:CGRectMake(point.x, scrollView.bounds.size.height / 2, 1, scrollView.bounds.size.height / self.preferredZoomScale) animated:YES];
                }
                    break;
                case DWMediaPreviewZoomTypeVertical:
                {
                    [scrollView zoomToRect:CGRectMake(scrollView.bounds.size.width / 2, point.y, scrollView.bounds.size.width / self.preferredZoomScale, 1) animated:YES];
                }
                    break;
                default:
                {
                    [scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];
                }
                    break;
            }
        }
    }
}

-(void)configPreviewController:(DWMediaPreviewController *)previewController {
    if (![_previewController isEqual:previewController]) {
        _previewController = previewController;
    }
}

#pragma mark --- private method ---
-(void)configIndex:(NSUInteger)index {
    _index = index;
}

#pragma mark --- call back method ---
+(Class)classForMediaView {
    return [UIImageView class];
}

-(void)initializingSubviews {
    [self.containerView addSubview:self.mediaView];
    [self.contentView addSubview:self.hdrBadge];
    [self.contentView addSubview:self.loadingIndicator];
}

-(void)setupSubviews {
    if (!CGRectEqualToRect(self.containerView.frame, self.bounds)) {
        if (self.zoomable) {
            _zoomContainerView.zoomScale = 1;
            _zoomContainerView.contentInset = UIEdgeInsetsZero;
            self.containerView.frame = self.bounds;
            _zoomContainerView.contentSize = self.bounds.size;
            [self configScaleFactorWithMediaSize:_mediaSize];
        }
    }
    if (!CGRectEqualToRect(self.mediaView.bounds, self.bounds)) {
        self.mediaView.frame = self.bounds;
    }
    if (!CGPointEqualToPoint(self.loadingIndicator.center, CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5))) {
        self.loadingIndicator.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    }
    [self.contentView bringSubviewToFront:self.loadingIndicator];
    if (_media) {
        [self configBadgeWithAnimated:YES];
    }
}

-(void)beforeZooming {
    if (self.enterFocus) {
        self.enterFocus(self,YES);
    }
    [self setBadgeHidden:YES animated:YES];
}

-(void)onZooming:(CGFloat)zoomScale {
    
}

-(void)afterZooming {
    
}

-(CGSize)sizeForMedia:(id)media {
    return CGSizeZero;
}

-(void)configScaleFactorWithMediaSize:(CGSize)mediaSize {
    if (!CGSizeEqualToSize(mediaSize, CGSizeZero)) {
        _mediaSize = mediaSize;
        CGFloat mediaScale = mediaSize.width / mediaSize.height;
        CGFloat previewScale = self.bounds.size.width / self.bounds.size.height;
        CGFloat zoomScale = mediaSize.width / self.bounds.size.width;
        if (zoomScale < 2) {
            zoomScale = 2;
        }
        DWMediaPreviewZoomType zoomDire = DWMediaPreviewZoomTypeNone;
        CGFloat preferrdScale = 1;
        CGFloat fixStartAnchor = 0;
        CGFloat fixEndAnchor = 0;
        if (CGFLOATEQUAL(mediaScale, previewScale)) {
            zoomDire = DWMediaPreviewZoomTypeNone;
            preferrdScale = 1;
            fixStartAnchor = 0;
            fixEndAnchor = 0;
        } else if (mediaScale / previewScale > 1) {
            zoomDire = DWMediaPreviewZoomTypeHorizontal;
            preferrdScale = mediaScale / previewScale;
            if (zoomScale < preferrdScale) {
                zoomScale = preferrdScale;
            }
            fixStartAnchor = (self.bounds.size.height - self.bounds.size.width / mediaScale) * 0.5;
            fixEndAnchor = (self.bounds.size.height + self.bounds.size.width / mediaScale) * 0.5;
        } else {
            zoomDire = DWMediaPreviewZoomTypeVertical;
            preferrdScale = previewScale / mediaScale;
            if (zoomScale < preferrdScale) {
                zoomScale = preferrdScale;
            }
            fixStartAnchor = (self.bounds.size.width - self.bounds.size.height * mediaScale) * 0.5;
            fixEndAnchor = (self.bounds.size.width + self.bounds.size.height * mediaScale) * 0.5;
        }
        _zoomContainerView.maximumZoomScale = zoomScale;
        self.zoomDirection = zoomDire;
        self.preferredZoomScale = preferrdScale;
        self.fixStartAnchor = fixStartAnchor;
        self.fixEndAnchor = fixEndAnchor;
    }
}

-(void)configBadgeWithAnimated:(BOOL)animated {
    if (!self.previewController.isFocusOnMedia) {
        if (!self.isHDR) {
            return;
        }
        if (!self.hdrBadge.image) {
            UIImage * hdr = [UIImage imageWithContentsOfFile:[self.imageBundle pathForResource:@"hdr_badge@3x" ofType:@"png"]];
            self.hdrBadge.image = hdr;
        }
        
        CGFloat spacing = 3;
        CGFloat badgeLength = 28;
        CGRect badgeFrame = CGRectMake(spacing, spacing, badgeLength, badgeLength);
        CGFloat zoomFactor = 1;
        if (self.zoomable) {
            zoomFactor = self.zoomContainerView.zoomScale;
        }
        switch (self.zoomDirection) {
            case DWMediaPreviewZoomTypeHorizontal:
            {
                CGFloat height = (self.fixEndAnchor - self.fixStartAnchor) * zoomFactor;
                badgeFrame.origin.y = (self.bounds.size.height - height) / 2;
            }
                break;
            case DWMediaPreviewZoomTypeVertical:
            {
                CGFloat width = (self.fixEndAnchor - self.fixStartAnchor) * zoomFactor;
                badgeFrame.origin.x = (self.bounds.size.width - width) / 2;
            }
                break;
            default:
                break;
        }
        
        
        
        CGFloat minY = 0;
        ///如果有toolBar，以toolBar的baseLine做基准
        if (self.previewController.topToolBar) {
            minY = [self.previewController.topToolBar baseline] + spacing;
        } else {
            ///如果没有已Navigation为准，如果是11以上，用safeAreaInsets更加准确
            if (@available(iOS 11.0,*)) {
                minY = self.safeAreaInsets.top + spacing;
            } else {
                minY = CGRectGetMaxY(self.previewController.navigationController.navigationBar.frame);
            }
        }
        
        if (badgeFrame.origin.y < minY) {
            badgeFrame.origin.y = minY;
        }
        if (badgeFrame.origin.x < spacing) {
            badgeFrame.origin.x = spacing;
        }
        self.hdrBadge.frame = badgeFrame;
        [self setBadgeHidden:NO animated:animated];
    } else {
        [self setBadgeHidden:YES animated:animated];
    }
}

-(void)setBadgeHidden:(BOOL)hidden animated:(BOOL)animated {
    if (!self.isHDR) {
        return;
    }
    CGFloat alpha = 1;
    if (hidden) {
        alpha = 0;
    }
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.hdrBadge.alpha = alpha;
        }];
    } else {
        self.hdrBadge.alpha = alpha;
    }
}

-(void)resetCellZoom {
    _zoomContainerView.zoomScale = 1;
    _zoomContainerView.maximumZoomScale = 1;
    _zoomContainerView.contentInset = UIEdgeInsetsZero;
    _zoomDirection = DWMediaPreviewZoomTypeNone;
    _scrollIsZooming = NO;
    _preferredZoomScale = 1;
    _fixStartAnchor = 0;
    _fixEndAnchor = 0;
}

-(void)zoomableHasBeenChangedTo:(BOOL)zoomable {
    _zoomContainerView.hidden = !zoomable;
    [self.containerView addSubview:self.mediaView];
}

-(void)tapAction:(UITapGestureRecognizer *)tap {
    if (self.tapAction) {
        self.tapAction(self);
    }
    ///如果没有导航控制器的话，不会走layoutSubviews。所以要处理一下角标
    if (!self.previewController.navigationController) {
        [self configBadgeWithAnimated:YES];
    } else if (self.previewController.topToolBar) {
        [self configBadgeWithAnimated:YES];
    }
}

-(void)doubleClickAction:(UITapGestureRecognizer *)doubleClick {
    if (self.doubleClickAction) {
        CGPoint point = [doubleClick locationInView:self.mediaView];
        self.doubleClickAction(self,point);
    }
}

#pragma mark --- tool method ---
-(void)configGestureTarget:(UIView *)target {
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [target addGestureRecognizer:tap];
    UITapGestureRecognizer * doubleClick = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClickAction:)];
    doubleClick.numberOfTapsRequired = 2;
    [target addGestureRecognizer:doubleClick];
    [tap requireGestureRecognizerToFail:doubleClick];
}

-(void)closeActionOnSlidingDown {
    if ([self.previewController.navigationController.viewControllers.lastObject isEqual:self.previewController]) {
        [self.previewController.navigationController popViewControllerAnimated:YES];
       
        if (self.onSlideCloseAction) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.onSlideCloseAction(self);
            });
        }
    } else {
        [self.previewController dismissViewControllerAnimated:YES completion:^{
            if (self.onSlideCloseAction) {
                self.onSlideCloseAction(self);
            }
        }];
    }
}

#pragma mark --- scroll delegate ---
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.mediaView;
}

-(void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [self beforeZooming];
    self.scrollIsZooming = YES;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    self.scrollIsZooming = NO;
    [self afterZooming];
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self onZooming:scrollView.zoomScale];
    CGFloat fixInset = 0;
    if (scrollView.zoomScale >= self.preferredZoomScale) {
        ///大于偏好缩放比则让inset为负的修正后的fixAnchor，这样则不会显示黑边
        fixInset = - ceil(self.fixStartAnchor * scrollView.zoomScale);
    } else {
        ///小于的时候应该由负的修正值线性过渡为正的修正值，这样可以避免临界处的跳动
        fixInset = - ceil(self.fixStartAnchor * (scrollView.zoomScale - 1) / (self.preferredZoomScale - 1));
    }
    
    switch (self.zoomDirection) {
        case DWMediaPreviewZoomTypeHorizontal:
        {
            ///横向缩放的黑边在上下
            scrollView.contentInset = UIEdgeInsetsMake(fixInset, 0, fixInset, 0);
        }
            break;
        case DWMediaPreviewZoomTypeVertical:
        {
            ///纵向缩放的黑边在左右
            scrollView.contentInset = UIEdgeInsetsMake(0, fixInset, 0, fixInset);
        }
        default:
            ///无向缩放本来就没有黑边
            break;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    ///避免缩放的时候看到黑边
    if (self.zooming) {
        switch (self.zoomDirection) {
            case DWMediaPreviewZoomTypeHorizontal:
            {
                ///小于偏好缩放比时屏幕纵向方向上仍能显示完成，所以将图片锁定在纵向居中
                if (scrollView.zoomScale < self.preferredZoomScale) {
                    CGFloat target = scrollView.contentSize.height * 0.5 - scrollView.bounds.size.height * 0.5;
                    if (scrollView.contentOffset.y != target) {
                        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, target);
                    }
                } else if (self.scrollIsZooming) {
                    ///大于缩放比以后为了避免看到黑边还是要监测纵向偏移量的两个临界值
                    if (scrollView.contentOffset.y < self.fixStartAnchor * scrollView.zoomScale) {
                        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.fixStartAnchor * scrollView.zoomScale)];
                    } else if (scrollView.contentOffset.y > self.fixEndAnchor * scrollView.zoomScale - scrollView.bounds.size.height) {
                        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.fixEndAnchor * scrollView.zoomScale - scrollView.bounds.size.height)];
                    }
                }
                
            }
                break;
            case DWMediaPreviewZoomTypeVertical:
            {
                ///小于偏好缩放比时屏幕纵向方向上仍能显示完成，所以将图片锁定在纵向居中
                if (scrollView.zoomScale < self.preferredZoomScale) {
                    CGFloat target = scrollView.contentSize.width * 0.5 - scrollView.bounds.size.width * 0.5;
                    if (scrollView.contentOffset.x != target) {
                        scrollView.contentOffset = CGPointMake(target, scrollView.contentOffset.y);
                    }
                } else if (self.scrollIsZooming) {
                    ///大于缩放比以后为了避免看到黑边还是要监测纵向偏移量的两个临界值
                    if (scrollView.contentOffset.x < self.fixStartAnchor * scrollView.zoomScale) {
                        [scrollView setContentOffset:CGPointMake(self.fixStartAnchor * scrollView.zoomScale, scrollView.contentOffset.y)];
                    } else if (scrollView.contentOffset.x > self.fixEndAnchor * scrollView.zoomScale - scrollView.bounds.size.width) {
                        [scrollView setContentOffset:CGPointMake(self.fixEndAnchor * scrollView.zoomScale - scrollView.bounds.size.width, scrollView.contentOffset.y)];
                    }
                }
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark --- gesture action ---
-(void)panGestureAction:(UIPanGestureRecognizer *)ges {
    if (![ges isEqual:self.panGes]) {
        return;
    }
    CGFloat currentY = [ges translationInView:self].y;
    CGFloat currentX = [ges translationInView:self].x;
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
        {
            ///首先判断手势方向
            if (currentX == 0 && currentY == 0) {
                self.panDirection = DWImagePanDirectionTypeNone;
            } else if (currentX == 0) {
                self.panDirection = DWImagePanDirectionTypeVertical;
            } else if (currentY == 0) {
                self.panDirection = DWImagePanDirectionTypeHorizontal;
            } else {
                if (fabs(currentY / currentX) >= 5.0) {
                    self.panDirection = DWImagePanDirectionTypeVertical;
                } else {
                    self.panDirection = DWImagePanDirectionTypeHorizontal;
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            ///nothing
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (self.panDirection == DWImagePanDirectionTypeVertical) {
                ///纵向可能是关闭动作，还是要看当前的缩放方向是否是横向，如果为非横向，有可能是滑动动作
                if (!self.previewController.closeOnSlidingDown) {
                    return;
                }
                
                BOOL needClose = NO;
                if (self.zooming && self.zoomDirection != DWMediaPreviewZoomTypeHorizontal) {
                    if (currentY > self.previewController.closeThreshold && _zoomContainerView.contentOffset.y <= 0 ) {
                        needClose = YES;
                    }
                } else if (currentY > self.previewController.closeThreshold && _zoomContainerView.contentOffset.y <= ceil(self.fixStartAnchor * _zoomContainerView.zoomScale)) {
                    needClose = YES;
                }
                
                if (needClose) {
                    [self closeActionOnSlidingDown];
                }
            }
            self.panDirection = DWImagePanDirectionTypeNone;
        }
            break;
        default:
            break;
    }
}

#pragma mark --- gesture delegate ---
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isEqual:_zoomContainerView.pinchGestureRecognizer]) {
        return NO;
    }
    return YES;
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _zoomable = YES;
        self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        self.panGes.delegate = self;
        [self addGestureRecognizer:self.panGes];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    if (!_finishInitializingLayout) {
        _finishInitializingLayout = YES;
        [self initializingSubviews];
    }
    [self setupSubviews];
}

-(void)prepareForReuse {
    [super prepareForReuse];
    [self clearCell];
}

#pragma mark --- setter/getter ---

-(void)setZoomable:(BOOL)zoomable {
    if (_zoomable != zoomable) {
        _zoomable = zoomable;
        [self zoomableHasBeenChangedTo:zoomable];
    }
}

-(void)setMedia:(id)media {
    _media = media;
    [self configScaleFactorWithMediaSize:[self sizeForMedia:media]];
    [self configBadgeWithAnimated:NO];
}

-(UIImageView *)mediaView {
    if (!_mediaView) {
        Class clazz = [[self class] classForMediaView];
        _mediaView = [[clazz alloc] init];
        _mediaView.contentMode = UIViewContentModeScaleAspectFit;
        _mediaView.clipsToBounds = YES;
        _mediaView.userInteractionEnabled = YES;
        [self configGestureTarget:_mediaView];
    }
    return _mediaView;
}

-(UIView *)containerView {
    return self.zoomable?self.zoomContainerView:self.contentView;
}

-(UIScrollView *)zoomContainerView {
    if (!_zoomContainerView) {
        _zoomContainerView = [[UIScrollView alloc] init];
        _zoomContainerView.showsVerticalScrollIndicator = NO;
        _zoomContainerView.showsHorizontalScrollIndicator = NO;
        _zoomContainerView.delegate = self;
        _zoomContainerView.maximumZoomScale = 5;
        _zoomContainerView.minimumZoomScale = 1;
        if (@available(iOS 11.0,*)) {
            _zoomContainerView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self.contentView addSubview:_zoomContainerView];
    }
    return _zoomContainerView;
}

-(UIImageView *)hdrBadge {
    if (!_hdrBadge) {
        _hdrBadge = [[UIImageView alloc] init];
    }
    return _hdrBadge;
}

-(BOOL)zooming {
    return self.zoomable && !CGFLOATEQUAL(((UIScrollView *)self.containerView).zoomScale, 1);
}

-(NSBundle *)imageBundle {
    if (!_imageBundle) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"DWMediaPreviewController" ofType:@"bundle"];
        _imageBundle = [NSBundle bundleWithPath:bundlePath];
    }
    return _imageBundle;
}

-(UIView<DWMediaPreviewLoadingProtocol> *)loadingIndicator {
    if (!_loadingIndicator) {
        _loadingIndicator = [DWMediaPreviewLoading new];
    }
    return _loadingIndicator;
}

@end

@interface DWNormalImagePreviewCell ()

@end

@implementation DWNormalImagePreviewCell
@dynamic media;

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.previewType = DWMediaPreviewTypeImage;
    }
    return self;
}

-(void)clearCell {
    [super clearCell];
    self.mediaView.image = nil;
}

-(CGSize)sizeForMedia:(UIImage *)media {
    return media.size;
}

#pragma mark --- setter/getter ---
-(void)setMedia:(UIImage *)media {
    [super setMedia:media];
    self.mediaView.image = media;
}

-(void)setPoster:(UIImage *)poster {
    [super setPoster:poster];
    self.mediaView.image = poster;
}


@end

@interface DWAnimateImagePreviewCell ()

@end

@implementation DWAnimateImagePreviewCell
@dynamic media;

#pragma mark --- override ---

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.previewType = DWMediaPreviewTypeAnimateImage;
    }
    return self;
}

-(void)resignFocus {
    [super resignFocus];
    ///结束展示时结束动画播放，但此时不必在getFocus时再开始播放，因为希望在同时看到两个cell时两个cell都可以进行播放
    if (self.mediaView.isAnimating) {
        [self.mediaView stopAnimating];
    }
}

-(void)clearCell {
    [super clearCell];
    self.mediaView.image = nil;
}

+(Class)classForMediaView {
    return [YYAnimatedImageView class];
}

-(CGSize)sizeForMedia:(YYImage *)media {
    return media.size;
}

#pragma mark --- setter/getter ---
-(void)setMedia:(YYImage *)media {
    [super setMedia:media];
    self.mediaView.image = media;
    [self.mediaView startAnimating];
}

-(void)setPoster:(UIImage *)poster {
    [super setPoster:poster];
    self.mediaView.image = poster;
}

@end

@interface DWLivePhotoPreviewCell ()<PHLivePhotoViewDelegate>

@property (nonatomic ,strong) UIImageView * posterView;

@property (nonatomic ,strong) PHLivePhotoView * mediaView;

@property (nonatomic ,assign) BOOL livePhotoIsPlaying;

@property (nonatomic ,strong) UIImageView * livePhotoBadge;

@end

@implementation DWLivePhotoPreviewCell
@dynamic media;
@dynamic mediaView;

#pragma mark --- live photo delegate ---
-(void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    self.livePhotoIsPlaying = YES;
}

-(void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    self.livePhotoIsPlaying = NO;
}

#pragma mark --- override ---

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.previewType = DWMediaPreviewTypeLivePhoto;
    }
    return self;
}

-(void)clearCell {
    [super clearCell];
    self.mediaView.livePhoto = nil;
    self.posterView.image = nil;
    self.livePhotoBadge.alpha = 0;
}

+(Class)classForMediaView {
    return [PHLivePhotoView class];
}

-(void)initializingSubviews {
    [super initializingSubviews];
    self.mediaView.delegate = self;
    if (self.zoomable) {
        [self.contentView insertSubview:self.posterView belowSubview:self.containerView];
    } else {
        [self.contentView insertSubview:self.posterView belowSubview:self.mediaView];
    }
    [self.contentView bringSubviewToFront:self.hdrBadge];
    [self.contentView addSubview:self.livePhotoBadge];
}

-(void)setupSubviews {
    [super setupSubviews];
    if (!CGRectEqualToRect(self.posterView.bounds, self.bounds)) {
        self.posterView.frame = self.bounds;
    }
}

-(CGSize)sizeForMedia:(PHLivePhoto *)media {
    return media.size;
}

-(void)configBadgeWithAnimated:(BOOL)animated {
    if (!self.previewController.isFocusOnMedia) {
        
        if (!self.livePhotoBadge.image) {
            self.livePhotoBadge.image = [PHLivePhotoView livePhotoBadgeImageWithOptions:(PHLivePhotoBadgeOptionsOverContent)];
        }
        
        CGFloat spacing = 3;
        CGRect badgeFrame = CGRectMake(spacing, spacing, self.livePhotoBadge.image.size.width, self.livePhotoBadge.image.size.height);
        CGFloat zoomFactor = 1;
        if (self.zoomable) {
            zoomFactor = self.zoomContainerView.zoomScale;
        }
        switch (self.zoomDirection) {
            case DWMediaPreviewZoomTypeHorizontal:
            {
                CGFloat height = (self.fixEndAnchor - self.fixStartAnchor) * zoomFactor;
                badgeFrame.origin.y = (self.bounds.size.height - height) / 2;
            }
                break;
            case DWMediaPreviewZoomTypeVertical:
            {
                CGFloat width = (self.fixEndAnchor - self.fixStartAnchor) * zoomFactor;
                badgeFrame.origin.x = (self.bounds.size.width - width) / 2;
            }
                break;
            default:
                break;
        }
        
        CGFloat minY = 0;
        ///如果有toolBar，以toolBar的baseLine做基准
        if (self.previewController.topToolBar) {
            minY = [self.previewController.topToolBar baseline] + spacing;
        } else {
            ///如果没有已Navigation为准，如果是11以上，用safeAreaInsets更加准确
            if (@available(iOS 11.0,*)) {
                minY = self.safeAreaInsets.top + spacing;
            } else {
                minY = CGRectGetMaxY(self.previewController.navigationController.navigationBar.frame);
            }
        }
        
        if (badgeFrame.origin.y < minY) {
            badgeFrame.origin.y = minY;
        }
        if (badgeFrame.origin.x < spacing) {
            badgeFrame.origin.x = spacing;
        }
        self.livePhotoBadge.frame = badgeFrame;
        
        if (self.isHDR) {
            
            if (!self.hdrBadge.image) {
                UIImage * hdr = [UIImage imageWithContentsOfFile:[self.imageBundle pathForResource:@"hdr_badge@3x" ofType:@"png"]];
                self.hdrBadge.image = hdr;
            }
            
            CGFloat badgeLength = 28;
            CGRect hdrBadgeFrame = CGRectMake(CGRectGetMaxX(badgeFrame) + spacing, badgeFrame.origin.y, badgeLength, badgeLength);
            self.hdrBadge.frame = hdrBadgeFrame;
        }
        [self setBadgeHidden:NO animated:animated];
    } else {
        [self setBadgeHidden:YES animated:animated];
    }
}

-(void)setBadgeHidden:(BOOL)hidden animated:(BOOL)animated {
    CGFloat alpha = 1;
    if (hidden) {
        alpha = 0;
    }
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            if (self.isHDR) {
                self.hdrBadge.alpha = alpha;
            }
            self.livePhotoBadge.alpha = alpha;
        }];
    } else {
        if (self.isHDR) {
            self.hdrBadge.alpha = alpha;
        }
        self.livePhotoBadge.alpha = alpha;
    }
}

-(void)tapAction:(UITapGestureRecognizer *)sender {
    if (self.livePhotoIsPlaying) {
        return;
    }
    [super tapAction:sender];
}

#pragma mark --- setter/getter ---
-(void)setMedia:(PHLivePhoto *)media {
    [super setMedia:media];
    self.mediaView.livePhoto = media;
    ///清除poster，否则缩放有底图
    self.posterView.image = nil;
}

-(void)setPoster:(UIImage *)poster {
    [super setPoster:poster];
    self.posterView.image = poster;
}

-(UIImageView *)posterView {
    if (!_posterView) {
        _posterView = [[UIImageView alloc] init];
        _posterView.contentMode = UIViewContentModeScaleAspectFit;
        _posterView.clipsToBounds = YES;
    }
    return _posterView;
}

-(UIImageView *)livePhotoBadge {
    if (!_livePhotoBadge) {
        _livePhotoBadge = [[UIImageView alloc] init];
    }
    return _livePhotoBadge;
}

@end

@interface DWVideoPreviewCell ()<DWPlayerManagerProtocol>

@property (nonatomic ,strong) UIImageView * posterView;

@property (nonatomic ,strong) DWPlayerView * mediaView;

@property (nonatomic ,strong) UIButton * playBtn;

@end

@implementation DWVideoPreviewCell
@dynamic media;
@dynamic mediaView;

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.previewType = DWMediaPreviewTypeVideo;
    }
    return self;
}

-(void)clearCell {
    [super clearCell];
    [self.mediaView configVideoWithAsset:nil];
    self.posterView.image = nil;
}

-(void)resignFocus {
    [super resignFocus];
    ///释放焦点时停止播放同时在获取焦点时再开始播放而不是setMedia，因为此处不希望同时看到两个视频播放
    [self stop];
}

+(Class)classForMediaView {
    return [DWPlayerView class];
}

-(void)initializingSubviews {
    [super initializingSubviews];
    self.mediaView.playerManager.delegate = self;
    if (self.zoomable) {
        [self.contentView insertSubview:self.posterView belowSubview:self.containerView];
    } else {
        [self.contentView insertSubview:self.posterView belowSubview:self.mediaView];
    }
    [self.contentView bringSubviewToFront:self.hdrBadge];
    [self.contentView addSubview:self.playBtn];
}

-(void)setupSubviews {
    [super setupSubviews];
    if (!CGRectEqualToRect(self.posterView.bounds, self.bounds)) {
        self.posterView.frame = self.bounds;
    }
    if (!CGPointEqualToPoint(self.playBtn.center, CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5))) {
        self.playBtn.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    }
}

-(CGSize)sizeForMedia:(AVPlayerItem *)media {
    NSArray *array = media.asset.tracks;
    CGSize videoSize = CGSizeZero;
    for (AVAssetTrack *track in array) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            videoSize = track.naturalSize;
        }
    }
    return videoSize;
}

-(void)tapAction:(UITapGestureRecognizer *)tap {
    [super tapAction:tap];
    if (self.mediaView.playerManager.status == DWPlayerPlaying) {
        [self pause];
    }
}

#pragma mark --- tool method ---
-(void)play {
    [self.mediaView play];
    self.playBtn.hidden = YES;
    if (self.enterFocus) {
        self.enterFocus(self,YES);
    }
    [self setBadgeHidden:YES animated:YES];
}

-(void)pause {
    [self.mediaView pause];
    self.playBtn.hidden = NO;
}

-(void)stop {
    [self.mediaView stop];
    self.playBtn.hidden = NO;
}

#pragma mark --- btn action ---
-(void)playBtnAction:(UIButton *)sender {
    [self play];
}

#pragma mark --- videoView delegate ---
-(void)playerManager:(DWPlayerManager *)manager readyToPlayForAsset:(AVAsset *)asset {
    ///清除poster，否则缩放有底图。更改时机为ready以后，防止 -setMedia: 时移除导致的视频尚未ready导致无法展示首帧，中间的等待时间为空白
    self.posterView.image = nil;
}

-(void)playerManager:(DWPlayerManager *)manager finishPlayingAsset:(AVAsset *)asset {
    [self stop];
}

#pragma mark --- setter/getter ---
-(void)setMedia:(AVPlayerItem *)media {
    [super setMedia:media];
    ///这里由于同一个AVPlayerItem不能赋给不同的AVPlayer对象，而当给 -[AVPlayer replaceCurrentItemWithPlayerItem:] 时，虽然解除了AVPlayer对AVPlayerItem的绑定关系，但是并不能接触AVPlayerItem对AVPlayer的绑定关系。导致下一次相同AVPlayerItem绑定至不同AVPlayer时崩溃的现象。这里防止此崩溃，采取绑定asset的或者直接-[media copy] 的形式避免崩溃
    [self.mediaView configVideoWithAsset:media.asset];
}

-(void)setPoster:(UIImage *)poster {
    [super setPoster:poster];
    self.posterView.image = poster;
}

-(UIImageView *)posterView {
    if (!_posterView) {
        _posterView = [[UIImageView alloc] init];
        _posterView.contentMode = UIViewContentModeScaleAspectFit;
        _posterView.clipsToBounds = YES;
    }
    return _posterView;
}

-(UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_playBtn setFrame:CGRectMake(0, 0, 80, 80)];
        ///使用这种方法加载bundle中的图片，提升图片加载速度，降低卡帧率。直接使用+[UIImage imageNamed:]会延迟图片解码时机，导致展示卡顿。
        UIImage * play = [UIImage imageWithContentsOfFile:[self.imageBundle pathForResource:@"play_btn@3x" ofType:@"png"]];
        [_playBtn setImage:play forState:(UIControlStateNormal)];
        [_playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
        _playBtn.backgroundColor = [UIColor blackColor];
        _playBtn.layer.cornerRadius = 40;
        _playBtn.alpha = 0.7;
    }
    return _playBtn;
}

@end

@interface DWVideoControlPreviewCell ()

@property (nonatomic ,strong) DWMediaPreviewVideoControl * control;

@end

@implementation DWVideoControlPreviewCell

#pragma mark --- tool method ---
-(void)hideControlWithAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.control.alpha = 0;
        } completion:^(BOOL finished) {
            self.control.hidden = YES;
        }];
    } else {
        self.control.hidden = YES;
        self.control.alpha = 0;
    }
}

-(void)showControlWithAnimated:(BOOL)animated {
    if (animated) {
        self.control.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.control.alpha = 1;
        }];
    } else {
        self.control.alpha = 1;
        self.control.hidden = NO;
    }
}

-(void)configControlWithItem:(AVPlayerItem *)item {
    CMTime total = [self.mediaView actualTimeForAsset:item.asset];
    self.control.totalTime = [self.mediaView convertCMTimeToTimeInterval:total];
    [self.control updateCurrentTime:0];
}

#pragma mark --- override ---
-(void)initializingSubviews {
    [super initializingSubviews];
    [self.contentView addSubview:self.control];
    self.mediaView.playerManager.timeIntervalForPlayerTimeObserver = 0.1;
}

-(void)setupSubviews {
    [super setupSubviews];
    
    CGFloat spacing = 10;
    CGFloat bottomMargin = 0;
    CGFloat leftMargin = 0;
    CGFloat height = 40;
    ///如果有toolBar，以toolBar的baseLine做基准
    if (self.previewController.bottomToolBar) {
        bottomMargin = [self.previewController.bottomToolBar baseline] + spacing;
    } else {
        ///如果没有已Navigation为准，如果是11以上，用safeAreaInsets更加准确
        if (@available(iOS 11.0,*)) {
            bottomMargin = self.safeAreaInsets.bottom + spacing;
        } else {
            bottomMargin = spacing;
        }
    }
    
    ///如果没有已Navigation为准，如果是11以上，用safeAreaInsets更加准确
    if (@available(iOS 11.0,*)) {
        leftMargin = self.safeAreaInsets.left + spacing;
    }
    
    CGRect controlFrame = CGRectMake(leftMargin, self.bounds.size.height - bottomMargin - height, self.bounds.size.width - leftMargin * 2, height);
    if (!CGRectEqualToRect(controlFrame, self.control.frame)) {
        self.control.frame = controlFrame;
    }
}

-(void)clearCell {
    [super clearCell];
    [self hideControlWithAnimated:NO];
    [self.control updateControlStatus:YES];
}

-(void)tapAction:(UITapGestureRecognizer *)tap {
    if (self.control.hidden) {
        [self showControlWithAnimated:YES];
    } else {
        [self hideControlWithAnimated:YES];
    }
    if (self.tapAction) {
        self.tapAction(self);
    }

    if (!self.previewController.navigationController) {
        [self configBadgeWithAnimated:YES];
    } else if (self.previewController.topToolBar) {
        [self configBadgeWithAnimated:YES];
    }
}

-(void)setMedia:(AVPlayerItem *)media {
    [super setMedia:media];
    [self configControlWithItem:media];
}

-(void)play {
    [super play];
    [self.control updateControlStatus:YES];
    [self hideControlWithAnimated:YES];
}

-(void)pause {
    [super pause];
    [self.control updateControlStatus:NO];
}

-(void)stop {
    [super stop];
    [self.control updateControlStatus:NO];
}

#pragma mark --- player delegate ---
-(void)playerManager:(DWPlayerManager *)manager playerTimeChangeTo:(CMTime)time forAsset:(AVAsset *)asset {
    NSTimeInterval currentTime = [self.mediaView convertCMTimeToTimeInterval:time];
    [self.control updateCurrentTime:currentTime];
}

#pragma mark --- setter/getter ---
-(DWMediaPreviewVideoControl *)control {
    if (!_control) {
        _control = [[DWMediaPreviewVideoControl alloc] initWithFrame:CGRectZero];
        _control.hidden = YES;
        __weak typeof(self)weakSelf = self;
        _control.playBtnClicked = ^(BOOL toPlay) {
            if (toPlay) {
                [weakSelf play];
            } else {
                [weakSelf pause];
            }
        };
        _control.sliderValueChanged = ^(NSTimeInterval totalDuration,CGFloat percent) {
            [weakSelf.mediaView seekToTimeContinuously:(totalDuration * percent) completionHandler:nil];
        };
        _control.sliderStatusChanged = ^(BOOL touchDown) {
            if (touchDown) {
                [weakSelf.mediaView beginSeekingTime];
            } else {
                [weakSelf.mediaView endSeekingTime];
            }
        };
    }
    return _control;
}

@end
