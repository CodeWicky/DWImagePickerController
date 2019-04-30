//
//  DWImagePreviewCell.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePreviewCell.h"
#import "DWTiledImageView.h"

#define CGFLOATEQUAL(a,b) (fabs(a - b) <= __FLT_EPSILON__)

typedef NS_ENUM(NSUInteger, DWImagePreviewZoomType) {
    DWImagePreviewZoomTypeNone,
    DWImagePreviewZoomTypeHorizontal,
    DWImagePreviewZoomTypeVertical,
};

typedef NS_ENUM(NSUInteger, DWImagePanDirectionType) {
    DWImagePanDirectionTypeNone,
    DWImagePanDirectionTypeHorizontal,
    DWImagePanDirectionTypeVertical,
};

@interface DWImagePreviewCell ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>
{
    BOOL _finishInitializingLayout;
}

@property (nonatomic ,strong) UIView * containerView;

@property (nonatomic ,strong) UIScrollView * zoomContainerView;

@property (nonatomic ,strong) UIImageView * imageView;

@property (nonatomic ,assign) CGSize mediaSize;

@property (nonatomic ,assign) DWImagePreviewZoomType zoomDirection;

@property (nonatomic ,assign) BOOL scrollIsZooming;

@property (nonatomic ,assign) CGFloat preferredZoomScale;

@property (nonatomic ,assign) CGFloat fixStartAnchor;

@property (nonatomic ,assign) CGFloat fixEndAnchor;

@property (nonatomic ,strong) UIPanGestureRecognizer * panGes;

@property (nonatomic ,assign) DWImagePanDirectionType panDirection;

@property (nonatomic ,assign) CGFloat closeThreshold;

@property (nonatomic ,weak) DWImagePreviewController * colVC;

@end

@implementation DWImagePreviewCell

#pragma mark --- interface method ---
-(void)configIndex:(NSUInteger)index {
    _index = index;
}

+(Class)classForPosterImageView {
    return [UIImageView class];
}

-(void)zoomPosterImageView:(BOOL)zoomIn point:(CGPoint)point {
    if (self.zoomable) {
        UIScrollView *scrollView = (UIScrollView *)self.containerView;
        if (!CGRectContainsPoint(self.imageView.bounds, point)) {
            return;
        }
        if (!zoomIn) {
            [scrollView setZoomScale:1 animated:YES];
        } else {
            switch (self.zoomDirection) {
                case DWImagePreviewZoomTypeHorizontal:
                {
                    ///缩放至指定位置（origin 指定的是期待缩放以后屏幕中心的位置，size展示在屏幕上全屏尺寸对应的原始尺寸，会取较小的值作为缩放比）
                    [scrollView zoomToRect:CGRectMake(point.x, scrollView.bounds.size.height / 2, 1, scrollView.bounds.size.height / self.preferredZoomScale) animated:YES];
                }
                    break;
                case DWImagePreviewZoomTypeVertical:
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

-(void)configCollectionViewController:(DWImagePreviewController *)colVC {
    if (![_colVC isEqual:colVC]) {
        _colVC = colVC;
    }
}

#pragma mark --- tool method ---

-(void)resetCellZoom {
    _zoomContainerView.zoomScale = 1;
    _zoomContainerView.maximumZoomScale = 1;
    _zoomContainerView.contentInset = UIEdgeInsetsZero;
    _zoomDirection = DWImagePreviewZoomTypeNone;
    _scrollIsZooming = NO;
    _preferredZoomScale = 1;
    _fixStartAnchor = 0;
    _fixEndAnchor = 0;
}

-(void)clearCell {
    [self resetCellZoom];
    _panDirection = DWImagePanDirectionTypeNone;
    _mediaSize = CGSizeZero;
    self.imageView.image = nil;
}

-(void)configGestureTarget:(UIView *)target {
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [target addGestureRecognizer:tap];
    UITapGestureRecognizer * doubleClick = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClickAction:)];
    doubleClick.numberOfTapsRequired = 2;
    [target addGestureRecognizer:doubleClick];
    [tap requireGestureRecognizerToFail:doubleClick];
}

-(void)zoomableHasBeenChangedTo:(BOOL)zoomable {
    _zoomContainerView.hidden = !zoomable;
    [self.containerView addSubview:self.imageView];
}

-(void)initializingSubviews {
    [self.containerView addSubview:self.imageView];
}

-(void)setupSubviews {
    if (!CGRectEqualToRect(self.containerView.frame, self.bounds)) {
        if (self.zoomable) {
            _zoomContainerView.zoomScale = 1;
            _zoomContainerView.contentInset = UIEdgeInsetsZero;
            self.containerView.frame = self.bounds;
            _zoomContainerView.contentSize = self.bounds.size;
            [self configZoomScaleWithMediaSize:_mediaSize];
        }
        self.imageView.frame = self.bounds;
    }
}

-(void)closeActionOnSlidingDown {
    if (self.colVC.closeOnSlidingDown) {
        if ([self.colVC.navigationController.viewControllers.lastObject isEqual:self.colVC]) {
            [self.colVC.navigationController popViewControllerAnimated:YES];
        } else {
            [self.colVC dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

-(void)configZoomScaleWithMediaSize:(CGSize)mediaSize {
    if (self.zoomable && !CGSizeEqualToSize(mediaSize, CGSizeZero)) {
        _mediaSize = mediaSize;
        CGFloat mediaScale = mediaSize.width / mediaSize.height;
        CGFloat previewScale = self.bounds.size.width / self.bounds.size.height;
        CGFloat zoomScale = mediaSize.width / self.bounds.size.width;
        if (zoomScale < 2) {
            zoomScale = 2;
        }
        DWImagePreviewZoomType zoomDire = DWImagePreviewZoomTypeNone;
        CGFloat preferrdScale = 1;
        CGFloat fixStartAnchor = 0;
        CGFloat fixEndAnchor = 0;
        if (CGFLOATEQUAL(mediaScale, previewScale)) {
            zoomDire = DWImagePreviewZoomTypeNone;
            preferrdScale = 1;
            fixStartAnchor = 0;
            fixEndAnchor = 0;
        } else if (mediaScale / previewScale > 1) {
            zoomDire = DWImagePreviewZoomTypeHorizontal;
            preferrdScale = mediaScale / previewScale;
            if (zoomScale < preferrdScale) {
                zoomScale = preferrdScale;
            }
            fixStartAnchor = (self.bounds.size.height - self.bounds.size.width / mediaScale) * 0.5;
            fixEndAnchor = (self.bounds.size.height + self.bounds.size.width / mediaScale) * 0.5;
        } else {
            zoomDire = DWImagePreviewZoomTypeVertical;
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

#pragma mark --- action ---
-(void)tapAction:(UITapGestureRecognizer *)tap {
    if (self.tapAction) {
        self.tapAction(self);
    }
}

-(void)doubleClickAction:(UITapGestureRecognizer *)doubleClick {
    if (self.doubleClickAction) {
        CGPoint point = [doubleClick locationInView:self.imageView];
        self.doubleClickAction(self,point);
    }
}

#pragma mark --- scroll delegate ---
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

-(void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollIsZooming = YES;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    self.scrollIsZooming = NO;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    CGFloat fixInset = 0;
    if (scrollView.zoomScale >= self.preferredZoomScale) {
        ///大于偏好缩放比则让inset为负的修正后的fixAnchor，这样则不会显示黑边
        fixInset = - ceil(self.fixStartAnchor * scrollView.zoomScale);
    } else {
        ///小于的时候应该由负的修正值g线性过渡为正的修正值，这样可以避免临界处的跳动
        fixInset = - ceil(self.fixStartAnchor * (scrollView.zoomScale - 1) / (self.preferredZoomScale - 1));
    }
    
    switch (self.zoomDirection) {
        case DWImagePreviewZoomTypeHorizontal:
        {
            ///横向缩放的黑边在上下
            scrollView.contentInset = UIEdgeInsetsMake(fixInset, 0, fixInset, 0);
        }
            break;
        case DWImagePreviewZoomTypeVertical:
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
            case DWImagePreviewZoomTypeHorizontal:
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
            case DWImagePreviewZoomTypeVertical:
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

#pragma mark --- gesture ---
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
                BOOL needClose = NO;
                if (self.zooming && self.zoomDirection != DWImagePreviewZoomTypeHorizontal) {
                    if (currentY > _closeThreshold && _zoomContainerView.contentOffset.y <= 0 ) {
                        needClose = YES;
                    }
                } else if (currentY > _closeThreshold && _zoomContainerView.contentOffset.y < ceil(self.fixStartAnchor * _zoomContainerView.zoomScale)) {
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
        self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        self.panGes.delegate = self;
        [self addGestureRecognizer:self.panGes];
        _closeThreshold = 100;
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
-(UIImageView *)imageView {
    if (!_imageView) {
        Class clazz = [[self class] classForPosterImageView];
        _imageView = [[clazz alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.clipsToBounds = YES;
        _imageView.userInteractionEnabled = YES;
        [self configGestureTarget:_imageView];
    }
    return _imageView;
}

-(void)setZoomable:(BOOL)zoomable {
    if (_zoomable != zoomable) {
        _zoomable = zoomable;
        [self zoomableHasBeenChangedTo:zoomable];
    }
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

-(BOOL)zooming {
    return self.zoomable && !CGFLOATEQUAL(((UIScrollView *)self.containerView).zoomScale, 1);
}

@end

@interface DWNormalImagePreviewCell ()

@end

@implementation DWNormalImagePreviewCell
@dynamic media;

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.zoomable = YES;
        self.previewType = DWImagePreviewTypeImage;
    }
    return self;
}

#pragma mark --- setter/getter ---
-(void)setMedia:(UIImage *)media {
    [super setMedia:media];
    self.imageView.image = media;
    [self configZoomScaleWithMediaSize:media.size];
}

@end

@interface DWAnimateImagePreviewCell ()

@end

@implementation DWAnimateImagePreviewCell
@dynamic media;

#pragma mark --- override ---
+(Class)classForPosterImageView {
    return [YYAnimatedImageView class];
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.zoomable = YES;
        self.previewType = DWImagePreviewTypeAnimateImage;
    }
    return self;
}

-(void)clearCell {
    [super clearCell];
    if (self.imageView.isAnimating) {
        [self.imageView stopAnimating];
    }
}

#pragma mark --- setter/getter ---
-(void)setMedia:(YYImage *)media {
    [super setMedia:media];
    self.imageView.image = media;
    if ([media isKindOfClass:[YYImage class]]) {
        [self configZoomScaleWithMediaSize:media.size];
        [self.imageView startAnimating];
    }
}

@end

@implementation DWLivePhotoPreviewCell
@dynamic media;

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.previewType = DWImagePreviewTypeLivePhoto;
    }
    return self;
}

@end

@implementation DWVideoPreviewCell
@dynamic media;

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.previewType = DWImagePreviewTypeVideo;
    }
    return self;
}

@end
