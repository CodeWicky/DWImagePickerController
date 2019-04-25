//
//  DWImagePreviewCell.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePreviewCell.h"

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

@property (nonatomic ,assign) DWImagePreviewZoomType zoomDirection;

@property (nonatomic ,assign) BOOL scrollIsZooming;

@property (nonatomic ,assign) CGFloat fix_anchor;

@property (nonatomic ,strong) UIPanGestureRecognizer * panGes;

@property (nonatomic ,assign) DWImagePanDirectionType panDirection;

@property (nonatomic ,weak) DWImagePreviewController * colVC;

@end

@implementation DWImagePreviewCell

#pragma mark --- interface method ---
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
                    [scrollView zoomToRect:CGRectMake(point.x, scrollView.bounds.size.height * 0.5, 1, 1) animated:YES];
                }
                    break;
                case DWImagePreviewZoomTypeVertical:
                {
                    [scrollView zoomToRect:CGRectMake(scrollView.bounds.size.width * 0.5, point.y, 1, 1) animated:YES];
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

-(void)configCollectionViewController:(UICollectionViewController *)colVC {
    _colVC = colVC;
}

#pragma mark --- tool method ---

-(void)resetCellZoom {
    _zoomContainerView.zoomScale = 1;
    _zoomDirection = DWImagePreviewZoomTypeNone;
    _scrollIsZooming = NO;
    _fix_anchor = 0;
    _panDirection = DWImagePanDirectionTypeNone;
}

-(void)clearCell {
    [self resetCellZoom];
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
    _zoomContainerView.contentSize = self.bounds.size;
    [self.containerView addSubview:self.imageView];
    self.imageView.frame = self.bounds;
}

-(void)closeActionOnSlidingDown {
    if (self.colVC.closeOnSlidingDown) {
        if (self.colVC.presentingViewController) {
            [self.colVC dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.colVC.navigationController popViewControllerAnimated:YES];
        }
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

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.zoomable && !self.scrollIsZooming && self.zooming) {
        switch (self.zoomDirection) {
            case DWImagePreviewZoomTypeHorizontal:
            {
                if (scrollView.contentOffset.y != self.fix_anchor) {
                    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, self.fix_anchor);
                }
            }
                break;
            case DWImagePreviewZoomTypeVertical:
            {
                if (scrollView.contentOffset.x != self.fix_anchor) {
                    scrollView.contentOffset = CGPointMake(self.fix_anchor, scrollView.contentOffset.y);
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
            if (self.panDirection == DWImagePanDirectionTypeVertical) {
                BOOL needClose = NO;
                if (self.zoomable && self.zoomDirection == DWImagePreviewZoomTypeVertical && self.zooming) {
                    if (_zoomContainerView.contentOffset.y <= 0 && currentY > 0) {
                        needClose = YES;
                    } else if (_zoomContainerView.contentOffset.y - (_zoomContainerView.contentSize.height - _zoomContainerView.bounds.size.height) > 0 && currentY < 0) {
                        needClose = YES;
                    }
                } else {
                    needClose = YES;
                }
                
                if (needClose) {
                    [self closeActionOnSlidingDown];
                }
                
            } else if (self.panDirection == DWImagePanDirectionTypeHorizontal) {
                NSLog(@"横向--> %f",currentX);
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (self.panDirection == DWImagePanDirectionTypeVertical) {
                NSLog(@"纵向结束了哦");
            } else if (self.panDirection == DWImagePanDirectionTypeHorizontal) {
                NSLog(@"横向结束了哦");
            }
            self.panDirection = DWImagePanDirectionTypeNone;
        }
            break;
        default:
            break;
    }
    [ges setTranslation:CGPointZero inView:self];
}

#pragma mark --- gesture delegate ---
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
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
    if (self.zoomable) {
        self.containerView.frame = self.bounds;
    }
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
        _zoomContainerView = [[UIScrollView alloc] initWithFrame:self.bounds];
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
    
    if (self.zoomable) {
        CGFloat mediaScale = media.size.width / media.size.height;
        CGFloat previewScale = self.bounds.size.width / self.bounds.size.height;
        if (CGFLOATEQUAL(mediaScale, previewScale)) {
            self.zoomDirection = DWImagePreviewZoomTypeNone;
            CGFloat zoomScale = media.size.width / self.bounds.size.width;
            if (zoomScale < 2) {
                zoomScale = 2;
            }
            self.zoomContainerView.maximumZoomScale = zoomScale;
        } else if (mediaScale / previewScale > 1) {
            self.zoomDirection = DWImagePreviewZoomTypeHorizontal;
            CGFloat zoomScale = mediaScale / previewScale;
            self.zoomContainerView.maximumZoomScale = zoomScale;
            self.fix_anchor = (self.bounds.size.height - self.bounds.size.width / mediaScale) * 0.5 * zoomScale;
        } else {
            self.zoomDirection = DWImagePreviewZoomTypeVertical;
            CGFloat zoomScale = previewScale / mediaScale;
            self.zoomContainerView.maximumZoomScale = zoomScale;
            self.fix_anchor = (self.bounds.size.width - self.bounds.size.height * mediaScale) * 0.5 * zoomScale;
        }
    }
}

@end

@interface DWAnimateImagePreviewCell ()

@end

@implementation DWAnimateImagePreviewCell
@dynamic media;

#pragma mark --- interface method ---
+(Class)classForPosterImageView {
    return [YYAnimatedImageView class];
}

#pragma mark --- override ---
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
