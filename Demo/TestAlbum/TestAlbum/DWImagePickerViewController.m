//
//  DWImagePickerViewController.m
//  TestAlbum
//
//  Created by Wicky on 2019/4/15.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePickerViewController.h"
#import <Photos/Photos.h>

@interface DWGridCell : UICollectionViewCell

@property (nonatomic ,strong) UIImageView * imageView;

@property (nonatomic ,copy) NSString * assetID;

@end

@implementation DWGridCell

#pragma mark --- override ---
-(void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
}

#pragma mark --- setter/getter ---
-(UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

@end

@interface DWImagePickerViewController ()<PHPhotoLibraryChangeObserver>

@property (nonatomic ,assign) CGRect previousPreheatRect;

@property (nonatomic ,strong) PHCachingImageManager * imageManager;

@property (nonatomic ,strong) PHFetchResult * result;

@property (nonatomic ,assign) CGSize photoSize;

@property (nonatomic ,assign) CGSize thumnailSize;

@property (nonatomic ,assign) CGFloat velocity;

@property (nonatomic ,assign) CGFloat lastOffsetY;

@property (nonatomic ,strong) PHImageRequestOptions * opt;

@end

@implementation DWImagePickerViewController

static NSString * const reuseIdentifier = @"Cell";

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
//    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    if (!self.result) {
        PHFetchOptions * opt = [[PHFetchOptions alloc] init];
        opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        self.result = [PHAsset fetchAssetsWithOptions:opt];
    }
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[DWGridCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGSize itemSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    CGFloat scale = 2;
    CGFloat thumnailScale = 0.5;
    self.photoSize = CGSizeMake(itemSize.width * scale, itemSize.height * scale);
    self.thumnailSize = CGSizeMake(itemSize.width * thumnailScale, itemSize.height * thumnailScale);
    PHImageRequestOptions * opt = [[PHImageRequestOptions alloc] init];
    opt.resizeMode = PHImageRequestOptionsResizeModeFast;
    self.opt = opt;
    
    [self.collectionView setContentOffset:CGPointMake(0, [self.collectionView.collectionViewLayout collectionViewContentSize].height - self.collectionView.bounds.size.height)];
}

//-(void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
////    [self updateCachedAssets];
//}

#pragma mark --- tool method ---
-(void)loadRealPhoto {
    CGRect visibleRect = (CGRect){self.collectionView.contentOffset,self.collectionView.bounds.size};
    NSArray <UICollectionViewLayoutAttributes *>* attrs = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:visibleRect];
    NSMutableArray * indexPaths = [NSMutableArray arrayWithCapacity:attrs.count];
    for (UICollectionViewLayoutAttributes * obj in attrs) {
        [indexPaths addObject:obj.indexPath];
    }
    
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

#pragma mark --- observer for Photos ---
-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails * changes = (PHFetchResultChangeDetails *)[changeInstance changeDetailsForFetchResult:self.result];
    if (!changes) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.result = changes.fetchResultAfterChanges;
        if (changes.hasIncrementalChanges) {
            UICollectionView * col = self.collectionView;
            if (col) {
                [col performBatchUpdates:^{
                    NSIndexSet * remove = changes.removedIndexes;
                    if (remove.count > 0) {
                        NSMutableArray * indexPaths = [NSMutableArray arrayWithCapacity:remove.count];
                        [remove enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                        }];
                        
                        [col deleteItemsAtIndexPaths:indexPaths];
                    }
                    
                    NSIndexSet * insert = changes.insertedIndexes;
                    if (insert.count > 0) {
                        NSMutableArray * indexPaths = [NSMutableArray arrayWithCapacity:insert.count];
                        [insert enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                        }];
                        
                        [col insertItemsAtIndexPaths:indexPaths];
                    }
                    
                    NSIndexSet * change = changes.changedIndexes;
                    if (change.count > 0) {
                        NSMutableArray * indexPaths = [NSMutableArray arrayWithCapacity:change.count];
                        [change enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                        }];
                        
                        [col reloadItemsAtIndexPaths:indexPaths];
                    }
                    
                    [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                        [col moveItemAtIndexPath:[NSIndexPath indexPathForRow:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForRow:toIndex inSection:0]];
                    }];
                } completion:nil];
            }
        } else {
            [self.collectionView reloadData];
        }
        //        [self resetCachedAssets];
    });
}

#pragma mark --- collectionView delegate ---
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.result.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset * asset = [self.result objectAtIndex:indexPath.row];
    DWGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.assetID = asset.localIdentifier;
    
    ///通过速度、滚动、偏移量联合控制是否展示缩略图
    ///显示缩略图的情景应为快速拖动，故前两个条件为判断快速及拖动
    ///1.速度
    ///2.拖动
    ///还要排除即将滚动到边缘时，这时强制加载原图，因为边缘的减速很快，非正常减速，
    ///所以会在高速情况下停止滚动，此时我们希望尽可能的看到的不是缩略图，所以对边缘做判断
    ///3.滚动边缘
    BOOL thumnail = NO;
    if (self.velocity > 30 && (collectionView.isDecelerating || collectionView.isDragging) && ((collectionView.contentSize.height - collectionView.contentOffset.y > collectionView.bounds.size.height * 3) && (collectionView.contentOffset.y > collectionView.bounds.size.height * 2))) {
        thumnail = YES;
    }

    CGSize targetSize = thumnail ? self.thumnailSize : self.photoSize;
    [self.imageManager requestImageForAsset:asset targetSize:targetSize contentMode:(PHImageContentModeAspectFill) options:self.opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([cell.assetID isEqualToString:asset.localIdentifier]) {
            cell.imageView.image = result;
        }
    }];
    
    return cell;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.velocity = fabs(scrollView.contentOffset.y - self.lastOffsetY);
    self.lastOffsetY = scrollView.contentOffset.y;
//    [self updateCachedAssets];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadRealPhoto];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadRealPhoto];
    }
}

#pragma mark --- override ---
-(void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark --- setter/getter ---
-(PHCachingImageManager *)imageManager {
    if (!_imageManager) {
        _imageManager = (PHCachingImageManager *)[PHCachingImageManager defaultManager];
    }
    return _imageManager;
}

#pragma mark --- optimization in Apple Demo ---
//-(void)resetCachedAssets {
//    [self.imageManager stopCachingImagesForAllAssets];
//    self.previousPreheatRect = CGRectZero;
//}

//-(void)updateCachedAssets {
//    if (!self.isViewLoaded || !self.view.window) {
//        return;
//    }
//    CGRect visibleRect = (CGRect){self.collectionView.contentOffset,self.collectionView.bounds.size};
//    CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
//
//    int delta = abs((int)(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect)));
//    if (delta <= (self.view.bounds.size.height / 3)) {
//        return;
//    }
//
//    CGRect add = minusRect(preheatRect, self.previousPreheatRect);
//    CGRect remove = minusRect(self.previousPreheatRect, preheatRect);
//
//    NSArray * addAssets = assetsForRect(self.collectionView, add, self.result);
//    NSArray * removeAssets = assetsForRect(self.collectionView, remove, self.result);
//
//    [self.imageManager startCachingImagesForAssets:addAssets targetSize:self.photoSize contentMode:(PHImageContentModeAspectFill) options:nil];
//    [self.imageManager stopCachingImagesForAssets:removeAssets targetSize:self.photoSize contentMode:(PHImageContentModeAspectFill) options:nil];
//    self.previousPreheatRect = preheatRect;
//
//}

//NS_INLINE CGRect minusRect(CGRect rectA,CGRect rectB) {
//    if (CGRectIntersectsRect(rectA, rectB)) {
//        return CGRectMake(rectA.origin.x, rectA.origin.y, rectA.size.width, fabs(CGRectGetMaxY(rectA) - CGRectGetMaxY(rectB)));
//    } else {
//        return rectA;
//    }
//}
//
//NS_INLINE NSArray <PHAsset *>* assetsForRect(UICollectionView * col,CGRect rect,PHFetchResult * result) {
//    NSArray <UICollectionViewLayoutAttributes *>* attrs = [col.collectionViewLayout layoutAttributesForElementsInRect:rect];
//    NSMutableArray * assets = [NSMutableArray arrayWithCapacity:attrs.count];
//    for (UICollectionViewLayoutAttributes * obj in attrs) {
//        [assets addObject:[result objectAtIndex:obj.indexPath.row]];
//    }
//    return [assets copy];
//}

@end
