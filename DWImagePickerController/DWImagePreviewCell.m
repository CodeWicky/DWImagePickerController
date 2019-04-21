//
//  DWImagePreviewCell.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePreviewCell.h"

@interface DWImagePreviewCell ()
{
    BOOL _finishInitializingLayout;
}

@property (nonatomic ,strong) UIView * containerView;

@property (nonatomic ,strong) UIScrollView * zoomContainerView;

@end

@implementation DWImagePreviewCell

#pragma mark --- tool method ---
-(void)clearCell {
    //implementation this in subclass
}

-(void)zoomableHasBeenChangedTo:(BOOL)zoomable {
    _zoomContainerView.hidden = !zoomable;
}

-(void)initializingSubviews {
    //implementation this in subclass
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
        [self.contentView addSubview:_zoomContainerView];
    }
    return _zoomContainerView;
}

@end

@interface DWNormalImagePreviewCell ()

@property (nonatomic ,strong) UIImageView * imageView;

@end

@implementation DWNormalImagePreviewCell
@dynamic media;

#pragma mark --- action ---
-(void)tapAction:(UITapGestureRecognizer *)tap {
    if (self.tapAction) {
        self.tapAction(self);
    }
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.zoomable = YES;
    }
    return self;
}

-(void)clearCell {
    self.imageView.image = nil;
}

-(void)zoomableHasBeenChangedTo:(BOOL)zoomable {
    [self.containerView addSubview:self.imageView];
}

-(void)initializingSubviews {
    [super initializingSubviews];
    [self.containerView addSubview:self.imageView];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}

#pragma mark --- setter/getter ---
-(void)setMedia:(UIImage *)media {
    [super setMedia:media];
    self.imageView.image = media;
}

-(UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.clipsToBounds = YES;
        _imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [_imageView addGestureRecognizer:tapGes];
    }
    return _imageView;
}

@end

@implementation DWAnimateImagePreviewCell
@dynamic media;

@end

@implementation DWPhotoLivePreviewCell
@dynamic media;

@end

@implementation DWVideoPreviewCell
@dynamic media;

@end
