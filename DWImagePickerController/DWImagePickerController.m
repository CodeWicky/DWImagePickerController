//
//  DWImagePickerController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/12.
//  Copyright © 2019 Wicky. All rights reserved.
//



#import "DWImagePickerController.h"
#import "DWAlbumToolBar.h"
#import "DWAlbumPreviewToolBar.h"
#import "DWAlbumPreviewNavigationBar.h"
#import "DWMediaPreviewCell.h"
#import "DWAlbumMediaHelper.h"
#import "DWAlbumGridCell.h"

@interface DWAlbumModel ()

-(void)configWithResult:(PHFetchResult *)result;

@end

@interface DWAlbumGridController ()

-(void)refreshGrid:(DWAlbumGridModel *)model;

@end

@interface DWImagePickerController ()<DWMediaPreviewDataSource,DWAlbumGridDataSource,PHPhotoLibraryChangeObserver>

@property (nonatomic ,strong) DWAlbumGridController * gridVC;

@property (nonatomic ,strong) DWAlbumListViewController * listVC;

@property (nonatomic ,strong) DWMediaPreviewController * previewVC;

@property (nonatomic ,strong) DWAlbumModel * currentAlbum;

@property (nonatomic ,strong) DWAlbumGridModel * currentGridModel;
//
//@property (nonatomic ,strong) PHFetchResult * currentGridAlbumResult;

@property (nonatomic ,assign) CGSize gridPhotoSize;

@property (nonatomic ,strong) dispatch_queue_t fetchMediaQueue;

@property (nonatomic ,strong) dispatch_queue_t preloadQueue;

@property (nonatomic ,strong) DWAlbumToolBar * gridBottomToolBar;

@property (nonatomic ,strong) DWAlbumPreviewNavigationBar * previewTopToolBar;

@property (nonatomic ,strong) DWAlbumPreviewToolBar * previewBottomToolBar;

@property (nonatomic ,strong) NSCache * posterCache;

@end

@implementation DWImagePickerController
@synthesize albumManager = _albumManager;
@synthesize selectionManager = _selectionManager;

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark --- interface method ---
-(instancetype)initWithAlbumManager:(DWAlbumManager *)albumManager fetchOption:(DWAlbumFetchOption *)fetchOption pickerConfiguration:(DWImagePickerConfiguration *)pickerConf columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing {
    if (self = [super init]) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        _albumManager = albumManager;
        _fetchOption = fetchOption;
        _pickerConf = pickerConf;
        _columnCount = columnCount;
        _spacing = spacing;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

-(void)configSelectionManager:(DWAlbumSelectionManager *)selectionManager {
    _selectionManager = selectionManager;
}

-(void)configGridVC:(DWAlbumGridController *)gridVC {
    _gridVC = gridVC;
}

-(void)configListVC:(DWAlbumListViewController *)listVC {
    _listVC = listVC;
}

-(void)configPreviewVC:(DWMediaPreviewController *)previewVC {
    _previewVC = previewVC;
}

-(void)fetchCameraRollWithCompletion:(dispatch_block_t)completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.albumManager fetchAlbumsWithOption:self.fetchOption completion:^(DWAlbumManager * _Nullable mgr, NSArray<DWAlbumModel *> * _Nullable obj) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self configAlbum:obj.firstObject];
                [self.listVC configWithAlbums:obj albumManager:self.albumManager];
                [self setViewControllers:@[self.listVC,self.gridVC]];
                if (completion) {
                    completion();
                }
            });
        }];
    });
}

+(instancetype)showImagePickerWithAlbumManager:(DWAlbumManager *)albumManager fetchOption:(DWAlbumFetchOption *)fetchOption pickerConfiguration:(DWImagePickerConfiguration *)pickerConf currentVC:(UIViewController *)currentVC {
    if (!currentVC) {
        return nil;
    }
    DWImagePickerController * imagePicker = [((DWImagePickerController *)[self alloc]) initWithAlbumManager:albumManager fetchOption:fetchOption pickerConfiguration:pickerConf columnCount:4 spacing:0.5];
    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
    [imagePicker fetchCameraRollWithCompletion:^{
        [currentVC presentViewController:imagePicker animated:YES completion:nil];
    }];
    return imagePicker;
}

#pragma mark --- tool method ---
-(DWMediaPreviewType)previewTypeForAsset:(PHAsset *)asset {
    DWAlbumMediaOption mediaOption = [DWAlbumMediaHelper mediaOptionForAsset:asset];
    switch (mediaOption) {
        case DWAlbumMediaOptionImage:
            return DWMediaPreviewTypeImage;
        case DWAlbumMediaOptionAnimateImage:
            return DWMediaPreviewTypeAnimateImage;
        case DWAlbumMediaOptionLivePhoto:
            return DWMediaPreviewTypeLivePhoto;
        case DWAlbumMediaOptionVideo:
            return DWMediaPreviewTypeVideo;
        default:
            return DWMediaPreviewTypeNone;
    }
}

-(void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)selectAtIndex:(NSInteger)index {
    if (index < self.currentGridModel.results.count) {
        PHAsset * asset = self.currentGridModel.results[index];
        NSInteger idx = [self.selectionManager indexOfSelection:asset];
        if (idx == NSNotFound) {
            if ([self.selectionManager addSelection:asset mediaIndex:index mediaOption:[DWAlbumMediaHelper mediaOptionForAsset:asset]]) {
                [self.previewTopToolBar setSelectAtIndex:self.selectionManager.selections.count];
                [self.previewBottomToolBar focusOnIndex:self.selectionManager.selections.count - 1];
                [self refreshToolBar];
                ///代表是0~1，代表bottomToolBar高度改变了，要刷新cell
                if (self.previewVC.isShowing && self.selectionManager.selections.count == 1) {
                    [self.previewVC refreshCurrentPreviewLayoutWithAnimated:YES];
                }
            }
        } else {
            if ([self.selectionManager removeSelection:asset]) {
                [self.previewTopToolBar setSelectAtIndex:0];
                [self.previewBottomToolBar focusOnIndex:NSNotFound];
                [self refreshToolBar];
                ///代表是1~0，代表bottomToolBar高度改变了，要刷新cell
                if (self.previewVC.isShowing && self.selectionManager.selections.count == 0) {
                    [self.previewVC refreshCurrentPreviewLayoutWithAnimated:YES];
                }
            }
        }
    }
}

-(void)fetchMediaWithAsset:(PHAsset *)asset previewType:(DWMediaPreviewType)previewType index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    NSInteger albumIndex = index;
    if (self.pickerConf.displayMediaOption != DWAlbumMediaOptionAll) {
        ///这里由于预览数据源跟album数据源存在差异（不在展示范围内的可能不会丢给预览控制器，所以要将预览控制器中的index转换成album对应的index）
        albumIndex = [self.currentAlbum.fetchResult indexOfObject:asset];
    }
    
    dispatch_async(self.fetchMediaQueue, ^{
        switch (previewType) {
            case DWMediaPreviewTypeLivePhoto:
            {
                [self fetchLivePhotoWithAsset:asset index:index albumIndex:albumIndex targetSize:targetSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
            }
                break;
            case DWMediaPreviewTypeVideo:
            {
                [self fetchVideoWithIndex:index albumIndex:albumIndex progressHandler:progressHandler fetchCompletion:fetchCompletion];
            }
                break;
            case DWMediaPreviewTypeAnimateImage:
            {
                [self fetchAnimateImageWithAsset:asset index:index albumIndex:albumIndex progressHandler:progressHandler fetchCompletion:fetchCompletion];
            }
                break;
            case DWMediaPreviewTypeNone:
            {
                ///do nothing
            }
                break;
            default:
            {
                ///如果是超尺寸大图，则降级图片尺寸
                CGFloat min_Length = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) * 1.0;
                if (asset.pixelWidth / min_Length > 3 && asset.pixelHeight / min_Length > 3) {
                    [self fetchBigImageWithAsset:asset index:index albumIndex:albumIndex progressHandler:progressHandler fetchCompletion:fetchCompletion];
                } else {
                    [self fetchOriginImageWithIndex:index albumIndex:albumIndex progressHandler:progressHandler fetchCompletion:fetchCompletion];
                }
            }
                break;
        }
    });
}

-(void)fetchLivePhotoWithAsset:(PHAsset *)asset index:(NSUInteger)index albumIndex:(NSUInteger)albumIndex targetSize:(CGSize)targetSize progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    
    [self.albumManager fetchLivePhotoWithAlbum:self.currentAlbum index:albumIndex targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progress,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWLivePhotoAssetModel * _Nullable obj) {
        if (fetchCompletion && !obj.isDegraded) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchVideoWithIndex:(NSUInteger)index albumIndex:(NSUInteger)albumIndex progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    [self.albumManager fetchVideoWithAlbum:self.currentAlbum index:albumIndex shouldCache:YES progrss:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWVideoAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchAnimateImageWithAsset:(PHAsset *)asset index:(NSUInteger)index albumIndex:(NSUInteger)albumIndex progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    
    [self.albumManager fetchOriginImageDataWithAlbum:self.currentAlbum index:albumIndex progress:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWImageDataAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchBigImageWithAsset:(PHAsset *)asset index:(NSUInteger)index albumIndex:(NSUInteger)albumIndex progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    CGFloat mediaScale = asset.pixelWidth * 1.0 / asset.pixelHeight;
    CGSize targetSize = CGSizeZero;
    CGFloat fixScale = [UIScreen mainScreen].scale;
    if (fixScale > 3) {
        fixScale = 3;
    }
    if (mediaScale == 1) {
        CGFloat width = _previewVC.previewSize.width * fixScale;
        targetSize =  CGSizeMake(width, width);
    } else if (mediaScale > 1) {
        CGFloat height = _previewVC.previewSize.height * fixScale;
        targetSize = CGSizeMake(height * mediaScale, height);
    } else {
        CGFloat width = _previewVC.previewSize.width * fixScale;
        targetSize = CGSizeMake(width, width / mediaScale);
    }
    
    [self.albumManager fetchImageWithAlbum:self.currentAlbum index:albumIndex targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progress,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        ///由于指定尺寸，所有亦可能有缩略图尺寸，如果是缩略图的话，不设置图片，已经有封面了
        if (fetchCompletion && !obj.isDegraded) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchOriginImageWithIndex:(NSUInteger)index albumIndex:(NSUInteger)albumIndex progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    [self.albumManager fetchOriginImageWithAlbum:self.currentAlbum index:albumIndex progress:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if (fetchCompletion && !obj.isDegraded) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)previewAtIndex:(NSInteger)index {
    if (index < self.currentGridModel.results.count) {
        [self.previewVC previewAtIndex:index];
        [self handleNavigationBarSelectedAtIndex:index];
        [self handlePreviewBottomToolFocusAtIndex:index];
        [self pushViewController:self.previewVC animated:YES];
    }
}

-(void)handleNavigationBarSelectedAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.currentGridModel.results objectAtIndex:index];
    NSUInteger idx = [self.selectionManager indexOfSelection:asset];
    ///调整idx。如果找不到改为0，因为navigationBar中规定0为未选中，如果找到则自加，因为规定角标从1开始
    if (idx == NSNotFound) {
        idx = 0;
    } else {
        ++ idx;
    }
    [((DWAlbumPreviewNavigationBar *)self.previewVC.topToolBar) setSelectAtIndex:idx];
}

-(void)configAlbum:(DWAlbumModel *)album {
    if (![self.currentAlbum isEqual:album]) {
        self.currentAlbum = album;
        self.currentGridModel = [self gridModelFromAlbumModel:album];
        [self.gridVC configWithGridModel:self.currentGridModel];
        [self.previewVC resetOnChangeDatasource];
    }
}

-(void)onPreviewBottomToolBarClick:(DWAlbumPreviewToolBar *)toolBar atIndex:(NSInteger)index {
    DWAlbumSelectionModel * selectionModel = [self.selectionManager selectionModelAtIndex:index];
    if ([self.currentGridModel.results containsObject:selectionModel.asset]) {
        [self.previewBottomToolBar focusOnIndex:index];
        [self.previewVC previewAtIndex:selectionModel.mediaIndex];
        [self handleNavigationBarSelectedAtIndex:selectionModel.mediaIndex];
    }
}

-(void)handlePreviewBottomToolFocusAtIndex:(NSUInteger)index {
    if (index >= self.currentGridModel.results.count) {
        [self.previewBottomToolBar focusOnIndex:NSNotFound];
    } else {
        PHAsset * asset = self.currentGridModel.results[index];
        index = [self.selectionManager indexOfSelection:asset];
        [self.previewBottomToolBar focusOnIndex:index];
    }
}

-(void)refreshToolBar {
    [self.gridBottomToolBar refreshSelection];
    [self.previewBottomToolBar refreshSelection];
}

-(DWAlbumGridModel *)gridModelFromAlbumModel:(DWAlbumModel *)album {
    DWAlbumGridModel * gridModel = [DWAlbumGridModel new];
    NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:album.count];
    DWAlbumMediaOption displayOption = self.pickerConf ? self.pickerConf.displayMediaOption : DWAlbumMediaOptionAll;
    if (displayOption == DWAlbumMediaOptionAll) {
        [album.fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [tmp addObject:obj];
        }];
    } else {
        [album.fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            DWAlbumMediaOption mediaOption = [DWAlbumMediaHelper mediaOptionForAsset:obj];
            if (displayOption & mediaOption) {
                [tmp addObject:obj];
            }
        }];
    }
    
    gridModel.results = [tmp copy];
    gridModel.name = album.name;
    return gridModel;
}

-(DWAlbumGridCellModel *)gridCellModelFromImageAssetModel:(DWImageAssetModel *)assetModel {
    DWAlbumGridCellModel * gridModel = [DWAlbumGridCellModel new];
    gridModel.asset = assetModel.asset;
    gridModel.media = assetModel.media;
    gridModel.mediaType = assetModel.mediaType;
    gridModel.targetSize = assetModel.targetSize;
    return gridModel;
}

-(NSIndexSet *)transformIndexesInGridModelToAlbum:(NSIndexSet *)indexes {
    if (self.pickerConf.displayMediaOption == DWAlbumMediaOptionAll) {
        return indexes;
    }
    NSMutableIndexSet * tmp = [NSMutableIndexSet indexSet];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        PHAsset * asset = self.currentGridModel.results[idx];
        NSInteger albumIndex = [self.currentAlbum.fetchResult indexOfObject:asset];
        [tmp addIndex:albumIndex];
    }];
    return [tmp copy];
}

#pragma mark --- gridViewController dataSource ---
-(void)gridController:(DWAlbumGridController *)gridController fetchMediaForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize thumnail:(BOOL)thumnail completion:(DWGridViewControllerFetchCompletion)completion {
    if (thumnail) {
        [self.albumManager fetchImageWithAsset:asset targetSize:targetSize networkAccessAllowed:self.currentAlbum.networkAccessAllowed progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
            if (completion) {
                completion([self gridCellModelFromImageAssetModel:obj]);
            }
        }];
    } else {
        NSInteger index = [self.currentAlbum.fetchResult indexOfObject:asset];
        [self.albumManager fetchImageWithAlbum:self.currentAlbum index:index targetSize:targetSize shouldCache:YES progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
            if (completion) {
                completion([self gridCellModelFromImageAssetModel:obj]);
            }
        }];
    }
}

-(void)gridViewController:(DWAlbumGridController *)gridController didSelectAsset:(PHAsset *)asset mediaOption:(DWAlbumMediaOption)mediaOption atIndex:(NSInteger)index {
    [self previewAtIndex:index];
}

-(void)gridController:(DWAlbumGridController *)gridController startCachingMediaForIndexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    indexes = [self transformIndexesInGridModelToAlbum:indexes];
    [self.albumManager startCachingImagesForAlbum:self.currentAlbum indexes:indexes targetSize:targetSize];
}

-(void)gridController:(DWAlbumGridController *)gridController stopCachingMediaForIndexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    indexes = [self transformIndexesInGridModelToAlbum:indexes];
    [self.albumManager stopCachingImagesForAlbum:self.currentAlbum indexes:indexes targetSize:targetSize];
}

#pragma mark --- previewController dataSource ---
-(NSUInteger)countOfMediaForPreviewController:(DWMediaPreviewController *)previewController {
    return self.currentGridModel.results.count;
}

-(DWMediaPreviewType)previewController:(DWMediaPreviewController *)previewController previewTypeAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.currentGridModel.results objectAtIndex:index];
    return [self previewTypeForAsset:asset];
}

-(DWMediaPreviewCell *)previewController:(DWMediaPreviewController *)previewController cellForItemAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    if (previewType != DWMediaPreviewTypeVideo) {
        return nil;
    }
    return [previewController dequeueReusablePreviewCellWithReuseIdentifier:@"videoControlCell" forIndex:index];
}

-(BOOL)previewController:(DWMediaPreviewController *)previewController isHDRAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    PHAsset * asset = [self.currentGridModel.results objectAtIndex:index];
    return asset.mediaSubtypes & PHAssetMediaSubtypePhotoHDR;
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    if (previewType == DWMediaPreviewTypeNone) {
        if (fetchCompletion) {
            fetchCompletion(nil,index);
        }
    } else {
        if (index >= self.currentGridModel.results.count) {
            if (fetchCompletion) {
                fetchCompletion(nil,index);
            }
            return ;
        }
        PHAsset * asset = [self.currentGridModel.results objectAtIndex:index];
        [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
    }
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchPosterAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType fetchCompletion:(DWMediaPreviewFetchPosterCompletion)fetchCompletion {
    if (index >= self.currentGridModel.results.count) {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
        return ;
    }
    
    PHAsset * asset = [self.currentGridModel.results objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeImage && asset.mediaType != PHAssetMediaTypeVideo) {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
        return ;
    }
    
    DWImageAssetModel * media = [self.posterCache objectForKey:asset];
    if (media) {
        if (fetchCompletion) {
            fetchCompletion(media.media,index,NO);
        }
        return;
    }
    
    [self.albumManager fetchImageWithAsset:asset targetSize:self.gridPhotoSize networkAccessAllowed:self.currentAlbum.networkAccessAllowed progress:nil completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
        if (obj.asset && obj.media) {
            [self.posterCache setObject:obj forKey:obj.asset];
            
            [DWAlbumMediaHelper cachePoster:[self gridCellModelFromImageAssetModel:obj] withAsset:obj.asset];
        }
        if (fetchCompletion) {
            fetchCompletion(obj.media,index,[obj satisfiedSize:previewController.previewSize]);
        }
    }];
}

-(void)previewController:(DWMediaPreviewController *)previewController prefetchMediaAtIndexes:(NSArray *)indexes fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    [indexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [obj integerValue];
        dispatch_async(self.preloadQueue, ^{
            PHAsset * asset = [self.currentGridModel.results objectAtIndex:index];
            DWMediaPreviewType previewType = [self previewTypeForAsset:asset];
            [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:nil fetchCompletion:fetchCompletion];
        });
    }];
}

-(void)previewController:(DWMediaPreviewController *)previewController hasChangedToIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    [self.gridVC notifyPreviewIndexChangeTo:index];
    [self handleNavigationBarSelectedAtIndex:index];
    [self handlePreviewBottomToolFocusAtIndex:index];
}

#pragma mark --- observer for Photos ---
-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails * changes = (PHFetchResultChangeDetails *)[changeInstance changeDetailsForFetchResult:self.currentAlbum.fetchResult];
    if (!changes) {
        return;
    }
    [self.currentAlbum configWithResult:changes.fetchResultAfterChanges];
    DWAlbumGridModel * newGrid = [self gridModelFromAlbumModel:self.currentAlbum];
    [self.gridVC refreshGrid:newGrid];
    dispatch_async(dispatch_get_main_queue(), ^{
        ///因为只有在全展示的情况下，changes中的角标变化与实际展示的变化才是一一对应的，可以用update。否则只能reload解决
        if (changes.hasIncrementalChanges && self.pickerConf.displayMediaOption == DWAlbumMediaOptionAll) {
            UICollectionView * col = self.gridVC.gridView;
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
                    
                    if (remove.count + insert.count > 0) {
                        [self.previewVC photoCountHasChanged];
                    }
                    
                    NSIndexSet * change = changes.changedIndexes;
                    if (change.count > 0) {
                        NSMutableArray * indexPaths = [NSMutableArray arrayWithCapacity:change.count];
                        [change enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                        }];
                        
                        [col reloadItemsAtIndexPaths:indexPaths];
                    }
                    
                    if (changes.hasMoves) {
                        [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                            [col moveItemAtIndexPath:[NSIndexPath indexPathForRow:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForRow:toIndex inSection:0]];
                        }];
                    }
                } completion:nil];
            }
        } else {
            [self.gridVC.gridView reloadData];
        }
    });
}

#pragma mark --- oveerride ---
-(void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark --- setter/getter ---
-(DWAlbumListViewController *)listVC {
    if (!_listVC) {
        _listVC = [[DWAlbumListViewController alloc] init];
        __weak typeof(self) weakSelf = self;
        _listVC.albumSelectAction = ^(DWAlbumModel *album, NSIndexPath *indexPath) {
            [weakSelf configAlbum:album];
            [weakSelf pushViewController:weakSelf.gridVC animated:YES];
        };
        _listVC.title = @"照片";
        _listVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _listVC.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
        _listVC.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
        _listVC.navigationItem.backBarButtonItem.tintColor = [UIColor blackColor];
    }
    return _listVC;
}

-(DWAlbumGridController *)gridVC {
    if (!_gridVC) {
        CGFloat shortSide = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        CGFloat width = (shortSide - (_columnCount - 1) * _spacing) / _columnCount;
        _gridVC = [[DWAlbumGridController alloc] initWithItemWidth:width];
        _gridVC.dataSource = self;
        _gridPhotoSize = CGSizeMake(width * 2, width * 2);
        _gridVC.selectionManager = self.selectionManager;
        _gridVC.bottomToolBar = self.gridBottomToolBar;
        _gridVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _gridVC.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
        _gridVC.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
        _gridVC.navigationItem.backBarButtonItem.tintColor = [UIColor blackColor];
    }
    return _gridVC;
}

-(DWMediaPreviewController *)previewVC {
    if (!_previewVC) {
        _previewVC = [[DWMediaPreviewController alloc] init];
        _previewVC.dataSource = self;
        [_previewVC registerClass:[DWVideoControlPreviewCell class] forCustomizePreviewCellWithReuseIdentifier:@"videoControlCell"];
        _previewVC.topToolBar = self.previewTopToolBar;
        _previewVC.bottomToolBar = self.previewBottomToolBar;
        _previewVC.closeOnSlidingDown = YES;
    }
    return _previewVC;
}

-(DWAlbumManager *)albumManager {
    if (!_albumManager) {
        _albumManager = [[DWAlbumManager alloc] init];
    }
    return _albumManager;
}

-(DWAlbumSelectionManager *)selectionManager {
    if (!_selectionManager) {
        _selectionManager = [[DWAlbumSelectionManager alloc] initWithMaxSelectCount:self.maxSelectCount selectableOption:(DWAlbumMediaOptionAll) multiTypeSelectionEnable:YES];
    }
    return _selectionManager;
}

-(dispatch_queue_t)fetchMediaQueue {
    if (!_fetchMediaQueue) {
        _fetchMediaQueue = dispatch_queue_create("com.wicky.dwimagepicker.fetchMediaQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _fetchMediaQueue;
}

-(dispatch_queue_t)preloadQueue {
    if (!_preloadQueue) {
        _preloadQueue = dispatch_queue_create("com.wicky.dwimagepicker.preloadQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _preloadQueue;
}

-(DWAlbumToolBar *)gridBottomToolBar {
    if (!_gridBottomToolBar) {
        _gridBottomToolBar = [DWAlbumToolBar toolBar];
        __weak typeof(self) weakSelf = self;
        _gridBottomToolBar.sendAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.selectionManager.sendAction) {
                strongSelf.selectionManager.sendAction(strongSelf.selectionManager);
            }
        };
        _gridBottomToolBar.previewAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            PHAsset * asset = strongSelf.selectionManager.selections.firstObject.asset;
            NSInteger idx = [strongSelf.gridVC.gridModel.results indexOfObject:asset];
            [strongSelf previewAtIndex:idx];
        };
        _gridBottomToolBar.originImageAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.selectionManager.useOriginImage = !strongSelf.selectionManager.useOriginImage;
            [strongSelf refreshToolBar];
        };
        [_gridBottomToolBar configWithSelectionManager:self.selectionManager];
    }
    return _gridBottomToolBar;
}

-(DWAlbumPreviewNavigationBar *)previewTopToolBar {
    if (!_previewTopToolBar) {
        _previewTopToolBar = [DWAlbumPreviewNavigationBar toolBar];
        __weak typeof(self) weakSelf = self;
        _previewTopToolBar.retAction = ^(DWAlbumPreviewNavigationBar *toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf popViewControllerAnimated:YES];
        };
        _previewTopToolBar.selectionAction = ^(DWAlbumPreviewNavigationBar *toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf selectAtIndex:strongSelf.previewVC.currentIndex];
        };
    }
    return _previewTopToolBar;
}

-(DWAlbumPreviewToolBar *)previewBottomToolBar {
    if (!_previewBottomToolBar) {
        _previewBottomToolBar = [DWAlbumPreviewToolBar toolBar];
        [_previewBottomToolBar configWithAlbumManager:self.albumManager networkAccessAllowed:self.fetchOption?self.fetchOption.networkAccessAllowed:YES];
        [_previewBottomToolBar configWithSelectionManager:self.selectionManager];
        __weak typeof(self) weakSelf = self;
        _previewBottomToolBar.selectAction = ^(DWAlbumPreviewToolBar * _Nonnull toolBar, NSInteger index) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf onPreviewBottomToolBarClick:toolBar atIndex:index];
        };
        _previewBottomToolBar.sendAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.selectionManager.sendAction) {
                strongSelf.selectionManager.sendAction(strongSelf.selectionManager);
            }
        };
        _previewBottomToolBar.originImageAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.selectionManager.useOriginImage = !strongSelf.selectionManager.useOriginImage;
            [strongSelf refreshToolBar];
        };
    }
    return _previewBottomToolBar;
}

-(NSCache *)posterCache {
    if (!_posterCache) {
        _posterCache = [[NSCache alloc] init];
    }
    return _posterCache;
}

@end

@implementation DWImagePickerConfiguration

@end
