//
//  DWImagePreviewController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePreviewController.h"
#import "DWImagePreviewCell.h"

@interface DWImagePreviewController ()

@property (nonatomic ,assign) CGFloat cellSpacing;

@property (nonatomic ,assign) CGFloat cellWidth;

@property (nonatomic ,assign) NSInteger index;

@property (nonatomic ,assign) BOOL indexChanged;

@property (nonatomic ,assign) BOOL sourceInteractivePopGestureEnabled;

@end


@implementation DWImagePreviewController

static NSString * const normalImageID = @"DWNormalImagePreviewCell";
static NSString * const animateImageID = @"DWAnimateImagePreviewCell";
static NSString * const photoLiveID = @"DWPhotoLivePreviewCell";
static NSString * const videoImageID = @"DWVideoPreviewCell";

#pragma mark --- interface method ---
-(void)previewAtIndex:(NSUInteger)index {
    if (index != _index && index < [self collectionView:self.collectionView numberOfItemsInSection:0]) {
        _index = index;
        _indexChanged = YES;
    }
}

#pragma mark --- tool method ---
-(void)showPreview {
    NSIndexPath * indexPath = [NSIndexPath indexPathForItem:_index inSection:0];
    if (_indexChanged) {
        _indexChanged = NO;
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:NO];
    }
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

-(void)clearPreview {
    DWImagePreviewCell * cell = (DWImagePreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0]];
    [cell clearCell];
}

-(void)setToolBarHidden:(BOOL)hidden {
    if (_isToolBarShowing == hidden) {
        [self.navigationController setNavigationBarHidden:hidden animated:YES];
        [self turnToDarkBackground:hidden];
        _isToolBarShowing = !hidden;
    }
}

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[DWNormalImagePreviewCell class] forCellWithReuseIdentifier:normalImageID];
    [self.collectionView registerClass:[DWAnimateImagePreviewCell class] forCellWithReuseIdentifier:animateImageID];
    [self.collectionView registerClass:[DWPhotoLivePreviewCell class] forCellWithReuseIdentifier:photoLiveID];
    [self.collectionView registerClass:[DWVideoPreviewCell class] forCellWithReuseIdentifier:videoImageID];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showPreview];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.sourceInteractivePopGestureEnabled = self.navigationController.interactivePopGestureRecognizer.enabled;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = self.sourceInteractivePopGestureEnabled;
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self clearPreview];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(countOfMediaForPreviewController:)]) {
        return [self.dataSource countOfMediaForPreviewController:self];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    DWImagePreviewType previewType = DWImagePreviewTypeNone;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:previewTypeAtIndex:)]) {
        previewType = [self.dataSource previewController:self previewTypeAtIndex:indexPath.row];
    }
    __kindof DWImagePreviewCell * cell;
    switch (previewType) {
        case DWImagePreviewTypeAnimateImage:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:animateImageID forIndexPath:indexPath];
        }
            break;
        case DWImagePreviewTypePhotoLive:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:photoLiveID forIndexPath:indexPath];
        }
            break;
        case DWImagePreviewTypeVideo:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:videoImageID forIndexPath:indexPath];
        }
            break;
        default:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:normalImageID forIndexPath:indexPath];
        }
            break;
    }
    
    if (previewType != DWImagePreviewTypeNone) {
        [self configGestureActionForCell:cell indexPath:indexPath previewType:previewType];
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:fetchMediaAtIndex:previewType:progress:fetchCompletion:)]) {
        [self.dataSource previewController:self fetchMediaAtIndex:indexPath.row previewType:previewType progress:^(double progress) {
            NSLog(@"%f",progress);
        } fetchCompletion:^(id  _Nonnull media, NSUInteger index ,BOOL preview) {
            
            NSLog(@"%@,%lu,%d",media,index,preview);
            
            if (index == indexPath.row) {
                if (!preview && previewType == DWImagePreviewTypeAnimateImage && media) {
                    YYImage * image = [[YYImage alloc] initWithData:media];
                    cell.media = image;
                } else {
                    cell.media = media;
                }
            }
        }];
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(DWImagePreviewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell resetCellZoom];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSInteger page = (scrollView.contentOffset.x - _cellWidth / 2) / (_cellWidth + _cellSpacing) + 1;

    if (velocity.x > 0) page++;
    if (velocity.x < 0) page--;
    page = MAX(page,0);
    _index = page;
    CGFloat newOffset = page * (_cellWidth + _cellSpacing);
    targetContentOffset->x = newOffset;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self previewDidChangedToIndex:scrollView];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self previewDidChangedToIndex:scrollView];
    }
}

#pragma mark --- tool method ---
-(void)previewDidChangedToIndex:(UIScrollView *)scrollView {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewContoller:hasChangedToIndex:)]) {
        NSInteger page = (scrollView.contentOffset.x - _cellWidth / 2) / (_cellWidth + _cellSpacing) + 1;
        [self.dataSource previewContoller:self hasChangedToIndex:page];
    }
}

-(void)configGestureActionForCell:(DWImagePreviewCell *)cell indexPath:(NSIndexPath *)indexPath previewType:(DWImagePreviewType)previewType {
    __weak typeof(self)weakSelf = self;
    cell.tapAction = ^(DWImagePreviewCell * _Nonnull cell) {
        __strong typeof(weakSelf)StrongSelf = weakSelf;
        [StrongSelf setToolBarHidden:StrongSelf.isToolBarShowing];
    };
    
    cell.doubleClickAction = ^(DWImagePreviewCell * _Nonnull cell ,CGPoint point) {
        __strong typeof(weakSelf)StrongSelf = weakSelf;
        if (StrongSelf.isToolBarShowing) {
            [StrongSelf setToolBarHidden:YES];
        }
        [cell zoomPosterImageView:!cell.zooming point:point];
    };
}

-(void)turnToDarkBackground:(BOOL)dark {
    [UIView animateWithDuration:0.2 animations:^{
        self.collectionView.backgroundColor = [UIColor colorWithWhite:dark?0:1 alpha:1];
    }];
}

#pragma mark --- override ---
-(instancetype)init {
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = [UIScreen mainScreen].bounds.size;
    layout.minimumLineSpacing = 40;
    if ([self initWithCollectionViewLayout:layout]) {
        _index = -1;
        _cellSpacing = layout.minimumLineSpacing;
        _cellWidth = layout.itemSize.width;
        _previewSize = layout.itemSize;
        _isToolBarShowing = YES;
        self.collectionView.decelerationRate = 0.5;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        if (@available(iOS 11.0,*)) {
            self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            self.automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
        }
    }
    return self;
}

@end
