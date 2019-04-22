//
//  DWImagePreviewCell.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePreviewCell.h"

#define CGFLOATEQUAL(a,b) (fabs(a - b) <= __FLT_EPSILON__)

@interface DWImagePreviewCell ()<UIScrollViewDelegate>
{
    BOOL _finishInitializingLayout;
}

@property (nonatomic ,strong) UIView * containerView;

@property (nonatomic ,strong) UIScrollView * zoomContainerView;

@property (nonatomic ,strong) UIImageView * imageView;

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
            [scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];
        }
    }
}

#pragma mark --- tool method ---

-(void)resetCellZoom {
    _zoomContainerView.zoomScale = 1;
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

#pragma mark --- override ---
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
        _zoomContainerView.bounces = NO;
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
    }
    return self;
}

#pragma mark --- setter/getter ---
-(void)setMedia:(UIImage *)media {
    [super setMedia:media];
    self.imageView.image = media;
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
    }
    return self;
}

#pragma mark --- setter/getter ---
-(void)setMedia:(YYImage *)media {
    [super setMedia:media];
    self.imageView.image = media;
}

@end

@implementation DWPhotoLivePreviewCell
@dynamic media;

@end

@implementation DWVideoPreviewCell
@dynamic media;

@end
