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

@property (nonatomic ,strong) UIPanGestureRecognizer * panGes;

@property (nonatomic ,assign) DWImagePanDirectionType panDirection;

@property (nonatomic ,weak) DWImagePreviewController * colVC;

@property (nonatomic ,assign) CGFloat verticalPanStartY;

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

-(void)configCollectionViewController:(DWImagePreviewController *)colVC {
    if (![_colVC isEqual:colVC]) {
        _colVC = colVC;
    }
}

#pragma mark --- tool method ---

-(void)resetCellZoom {
    _zoomContainerView.zoomScale = 1;
    _zoomDirection = DWImagePreviewZoomTypeNone;
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

-(void)configZoomScaleWithMediaSize:(CGSize)mediaSize {
    if (self.zoomable) {
        CGFloat mediaScale = mediaSize.width / mediaSize.height;
        CGFloat previewScale = self.bounds.size.width / self.bounds.size.height;
        CGFloat zoomScale = 1;
        if (CGFLOATEQUAL(mediaScale, previewScale)) {
            self.zoomDirection = DWImagePreviewZoomTypeNone;
            zoomScale = mediaSize.width / self.bounds.size.width;
            if (zoomScale < 2) {
                zoomScale = 2;
            }
        } else if (mediaScale / previewScale > 1) {
            self.zoomDirection = DWImagePreviewZoomTypeHorizontal;
            zoomScale = mediaScale / previewScale;
        } else {
            self.zoomDirection = DWImagePreviewZoomTypeVertical;
            zoomScale = previewScale / mediaScale;
        }
        _zoomContainerView.maximumZoomScale = zoomScale;
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

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.zooming) {
        switch (self.zoomDirection) {
            case DWImagePreviewZoomTypeHorizontal:
            {
                CGFloat target = scrollView.contentSize.height * 0.5 - scrollView.bounds.size.height * 0.5;
                if (scrollView.contentOffset.y != target) {
                    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, target);
                }
            }
                break;
            case DWImagePreviewZoomTypeVertical:
            {
                CGFloat target = scrollView.contentSize.width * 0.5 - scrollView.bounds.size.width * 0.5;
                if (scrollView.contentOffset.x != target) {
                    scrollView.contentOffset = CGPointMake(target, scrollView.contentOffset.y);
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
                self.verticalPanStartY = currentY;
            } else if (currentY == 0) {
                self.panDirection = DWImagePanDirectionTypeHorizontal;
            } else {
                if (fabs(currentY / currentX) >= 5.0) {
                    self.panDirection = DWImagePanDirectionTypeVertical;
                    self.verticalPanStartY = currentY;
                } else {
                    self.panDirection = DWImagePanDirectionTypeHorizontal;
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            ///横向可能是切换动作，还是要看当前的缩放方向是否是横向，如果是横向，则不需要用手势控制切换动作
            if (self.panDirection == DWImagePanDirectionTypeHorizontal) {
                if (self.zooming && self.zoomDirection == DWImagePreviewZoomTypeVertical) {
                    NSLog(@"横向--> %f",currentX);
                }
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (self.panDirection == DWImagePanDirectionTypeVertical) {
                ///纵向可能是关闭动作，还是要看当前的缩放方向是否是横向，如果为非横向，有可能是滑动动作
                BOOL needClose = NO;
                if (self.zooming && self.zoomDirection != DWImagePreviewZoomTypeHorizontal) {
                    if (_zoomContainerView.contentOffset.y <= 0 && currentY > 30) {
                        needClose = YES;
                    }
                } else if (currentY > 30) {
                    needClose = YES;
                }
                
                if (needClose) {
                    [self closeActionOnSlidingDown];
                }
            } else if (self.panDirection == DWImagePanDirectionTypeHorizontal) {
                ///横向可能是切换动作，还是要看当前的缩放方向是否是横向，如果是横向，则不需要用手势控制切换动作
                if (self.panDirection == DWImagePanDirectionTypeHorizontal) {
                    if (self.zooming && self.zoomDirection == DWImagePreviewZoomTypeVertical) {
                        if (fabs(currentX) > self.bounds.size.width * 0.5) {
                            NSLog(@"横滑过半页了哦");
                        } else {
                            NSLog(@"横滑没够哟");
                        }
                    }
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
    [self configZoomScaleWithMediaSize:media.size];
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
        [self configZoomScaleWithMediaSize:media.size];
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

@implementation DWBigImagePreviewCell
@dynamic media;

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.previewType = DWImagePreviewTypeBigImage;
    }
    return self;
}

@end

@interface DWTiledImageView ()

@property (nonatomic ,strong) CATiledLayer * tiledLayer;

@property (nonatomic ,assign) CGFloat imageScale;

@property (nonatomic ,assign) CGFloat mediaScale;

@property (nonatomic ,assign) CGFloat viewScale;

@property (nonatomic ,assign) CGFloat viewWidth;

@property (nonatomic ,assign) CGFloat viewHeight;

@end

@implementation DWTiledImageView

#pragma mark --- tool method ---
-(void)calculateImageScale {
    if (_viewScale * _mediaScale != 0) {
        if (_mediaScale / _viewScale > 1) {
            _imageScale = _viewWidth / _image.size.width;
        } else {
            _imageScale = _viewHeight / _image.size.height;
        }
        int lev = ceil(log2( 1 / _imageScale ))+1;
        self.tiledLayer.levelsOfDetailBias = lev;
    } else {
        _imageScale = 0;
    }
}

#pragma mark --- override ---
+(Class)layerClass {
    return [CATiledLayer class];
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.mediaScale * self.viewScale == 0) {
        return;
    }
    
    CGRect imageCutRect = CGRectZero;
    
    CGFloat zoomScale = self.mediaScale / self.viewScale;
    
    if (zoomScale > 1) {
        imageCutRect = CGRectMake(rect.origin.x / self.imageScale, (rect.origin.y - self.bounds.size.height * (1 -  1 / zoomScale) * 0.5) / self.imageScale , rect.size.width / self.imageScale, rect.size.height / self.imageScale);
    } else if (zoomScale < 1) {
        imageCutRect = CGRectMake((rect.origin.x - self.bounds.size.width * (1 - zoomScale) * 0.5 ) / self.imageScale, rect.origin.y / self.imageScale, rect.size.width / self.imageScale, rect.size.height / self.imageScale);
    } else {
        imageCutRect = CGRectMake(rect.origin.x / self.imageScale,rect.origin.y / self.imageScale,rect.size.width / self.imageScale,rect.size.height / self.imageScale);
    }
    
    @autoreleasepool{
        CGImageRef imageRef = CGImageCreateWithImageInRect(self.image.CGImage, imageCutRect);
        UIImage *tileImage = [UIImage imageWithCGImage:imageRef];
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        [tileImage drawInRect:rect];
        UIGraphicsPopContext();
    }
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.tiledLayer.levelsOfDetail = 1;
        self.tileSize = CGSizeMake(25, 25);
    }
    return self;
}

#pragma mark --- setter/getter ---
-(CATiledLayer *)tiledLayer {
    return (CATiledLayer *)self.layer;
}

-(void)setTileSize:(CGSize)tileSize {
    if (!CGSizeEqualToSize(_tileSize, tileSize)) {
        _tileSize = tileSize;
        int widthFactor = ceil(self.bounds.size.width / tileSize.width);
        int heightFactor = ceil(self.bounds.size.height / tileSize.height);
        self.tiledLayer.tileSize = CGSizeMake(_viewWidth / widthFactor, _viewHeight / heightFactor);
    }
}

-(void)setImage:(UIImage *)image {
    if (![_image isEqual:image]) {
        _image = image;
        if (image.size.height * image.size.width > 0) {
            _mediaScale = fabs(image.size.width / image.size.height);
        } else {
            _mediaScale = 0;
        }
        [self calculateImageScale];
    }
}

-(void)setFrame:(CGRect)frame {
    if (!CGRectEqualToRect(self.frame, frame)) {
        [super setFrame:frame];
        _viewWidth = frame.size.width;
        _viewHeight = frame.size.height;
        if (_viewHeight != 0) {
            _viewScale = fabs(_viewWidth / _viewHeight);
        } else {
            _viewScale = 0;
        }
        [self calculateImageScale];
    }
}

@end
