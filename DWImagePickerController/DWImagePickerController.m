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

@interface DWAlbumModel ()

-(void)configWithResult:(PHFetchResult *)result;

@end

@interface DWAlbumGridViewController ()

-(void)refreshAlbum:(DWAlbumModel *)model;

@end

@interface DWImagePickerController ()<DWMediaPreviewDataSource,PHPhotoLibraryChangeObserver>

@property (nonatomic ,strong) DWAlbumGridViewController * gridVC;

@property (nonatomic ,strong) DWAlbumListViewController * listVC;

@property (nonatomic ,strong) DWMediaPreviewController * previewVC;

@property (nonatomic ,strong) DWAlbumModel * currentGridAlbum;

@property (nonatomic ,strong) PHFetchResult * currentGridAlbumResult;

@property (nonatomic ,assign) CGSize gridPhotoSize;

@property (nonatomic ,strong) dispatch_queue_t fetchMediaQueue;

@property (nonatomic ,strong) dispatch_queue_t preloadQueue;

@end

@implementation DWImagePickerController
@synthesize albumManager = _albumManager;
@synthesize selectionManager = _selectionManager;

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark --- interface method ---
-(instancetype)initWithAlbumManager:(DWAlbumManager *)albumManager option:(DWAlbumFetchOption *)opt columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing {
    if (self = [super init]) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        _albumManager = albumManager;
        _fetchOption = opt;
        _columnCount = columnCount;
        _spacing = spacing;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

-(void)configSelectionManager:(DWAlbumSelectionManager *)selectionManager {
    _selectionManager = selectionManager;
}

-(void)configGridVC:(DWAlbumGridViewController *)gridVC {
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

+(instancetype)showImagePickerWithAlbumManager:(DWAlbumManager *)albumManager option:(DWAlbumFetchOption *)opt currentVC:(UIViewController *)currentVC {
    if (!currentVC) {
        return nil;
    }
    DWImagePickerController * imagePicker = [((DWImagePickerController *)[self alloc]) initWithAlbumManager:albumManager option:opt columnCount:4 spacing:0.5];
    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
    [imagePicker fetchCameraRollWithCompletion:^{
        [currentVC presentViewController:imagePicker animated:YES completion:nil];
    }];
    return imagePicker;
}

#pragma mark --- tool method ---
-(void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)selectAtIndex:(NSInteger)index {
    if (index < self.currentGridAlbumResult.count) {
        PHAsset * asset = self.currentGridAlbumResult[index];
        NSInteger idx = [self.selectionManager indexOfSelection:asset];
        if (idx == NSNotFound) {
            if ([self.selectionManager addSelection:asset mediaIndex:index previewType:[DWAlbumMediaHelper previewTypeForAsset:asset]]) {
                [((DWAlbumPreviewNavigationBar *)self.previewVC.topToolBar) setSelectAtIndex:self.selectionManager.selections.count];
            }
        } else {
            [self.selectionManager removeSelection:asset];
            [((DWAlbumPreviewNavigationBar *)self.previewVC.topToolBar) setSelectAtIndex:0];
        }
    }
}

-(void)fetchMediaWithAsset:(PHAsset *)asset previewType:(DWMediaPreviewType)previewType index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    dispatch_async(self.fetchMediaQueue, ^{
        switch (previewType) {
            case DWMediaPreviewTypeLivePhoto:
            {
                [self fetchLivePhotoWithAsset:asset index:index targetSize:targetSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
            }
                break;
            case DWMediaPreviewTypeVideo:
            {
                [self fetchVideoWithIndex:index progressHandler:progressHandler fetchCompletion:fetchCompletion];
            }
                break;
            case DWMediaPreviewTypeAnimateImage:
            {
                [self fetchAnimateImageWithAsset:asset index:index progressHandler:progressHandler fetchCompletion:fetchCompletion];
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
                    [self fetchBigImageWithAsset:asset index:index progressHandler:progressHandler fetchCompletion:fetchCompletion];
                } else {
                    [self fetchOriginImageWithIndex:index progressHandler:progressHandler fetchCompletion:fetchCompletion];
                }
            }
                break;
        }
    });
}

-(void)fetchLivePhotoWithAsset:(PHAsset *)asset index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    
    [self.albumManager fetchLivePhotoWithAlbum:self.currentGridAlbum index:index targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progress,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWLivePhotoAssetModel * _Nullable obj) {
        if (fetchCompletion && !obj.isDegraded) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchVideoWithIndex:(NSUInteger)index progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    [self.albumManager fetchVideoWithAlbum:self.currentGridAlbum index:index shouldCache:YES progrss:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWVideoAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchAnimateImageWithAsset:(PHAsset *)asset index:(NSUInteger)index progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    
    [self.albumManager fetchOriginImageDataWithAlbum:self.currentGridAlbum index:index progress:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum,index);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWImageDataAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchBigImageWithAsset:(PHAsset *)asset index:(NSUInteger)index progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
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
    
    [self.albumManager fetchImageWithAlbum:self.currentGridAlbum index:index targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
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

-(void)fetchOriginImageWithIndex:(NSUInteger)index progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    [self.albumManager fetchOriginImageWithAlbum:self.currentGridAlbum index:index progress:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
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
    if (index < self.currentGridAlbumResult.count) {
        [self.previewVC previewAtIndex:index];
        [self handleNavigationBarSelectedAtIndex:index];
        [self pushViewController:self.previewVC animated:YES];
    }
}

-(void)handleNavigationBarSelectedAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.currentGridAlbumResult objectAtIndex:index];
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
    if (![self.currentGridAlbum isEqual:album]) {
        self.currentGridAlbumResult = album.fetchResult;
        self.currentGridAlbum = album;
        [self.gridVC configWithAlbum:album albumManager:self.albumManager];
        [self.previewVC resetOnChangeDatasource];
    }
}

#pragma mark --- previewController dataSource ---
-(NSUInteger)countOfMediaForPreviewController:(DWMediaPreviewController *)previewController {
    return self.currentGridAlbumResult.count;
}

-(DWMediaPreviewType)previewController:(DWMediaPreviewController *)previewController previewTypeAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.currentGridAlbumResult objectAtIndex:index];
    return [DWAlbumMediaHelper previewTypeForAsset:asset];
}

-(DWMediaPreviewCell *)previewController:(DWMediaPreviewController *)previewController cellForItemAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    if (previewType != DWMediaPreviewTypeVideo) {
        return nil;
    }
    return [previewController dequeueReusablePreviewCellWithReuseIdentifier:@"videoControlCell" forIndex:index];
}

-(BOOL)previewController:(DWMediaPreviewController *)previewController isHDRAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    PHAsset * asset = [self.currentGridAlbumResult objectAtIndex:index];
    return asset.mediaSubtypes & PHAssetMediaSubtypePhotoHDR;
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    if (previewType == DWMediaPreviewTypeNone) {
        if (fetchCompletion) {
            fetchCompletion(nil,index);
        }
    } else {
        PHAsset * asset = [self.currentGridAlbumResult objectAtIndex:index];
        [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
    }
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchPosterAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType fetchCompletion:(DWMediaPreviewFetchPosterCompletion)fetchCompletion {
    if (index >= self.currentGridAlbumResult.count) {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
        return ;
    }
    
    PHAsset * asset = [self.currentGridAlbumResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeImage && asset.mediaType != PHAssetMediaTypeVideo) {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
        return ;
    }
    
    DWImageAssetModel * media = [DWAlbumMediaHelper posterCacheForAsset:asset];
    if (media) {
        if (fetchCompletion) {
            fetchCompletion(media.media,index,NO);
        }
        return;
    }
    
    [self.albumManager fetchImageWithAsset:asset targetSize:self.gridPhotoSize networkAccessAllowed:self.currentGridAlbum.networkAccessAllowed progress:nil completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
        if (obj.asset && obj.media) {
            [DWAlbumMediaHelper cachePoster:obj withAsset:obj.asset];
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
            NSLog(@"start preload %ld",(long)index);
            PHAsset * asset = [self.currentGridAlbumResult objectAtIndex:index];
            DWMediaPreviewType previewType = [DWAlbumMediaHelper previewTypeForAsset:asset];
            [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:nil fetchCompletion:fetchCompletion];
        });
    }];
}

-(void)previewController:(DWMediaPreviewController *)previewController hasChangedToIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    [self.gridVC notifyPreviewIndexChangeTo:index];
    [self handleNavigationBarSelectedAtIndex:index];
}

#pragma mark --- observer for Photos ---
-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails * changes = (PHFetchResultChangeDetails *)[changeInstance changeDetailsForFetchResult:self.currentGridAlbumResult];
    if (!changes) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentGridAlbumResult = changes.fetchResultAfterChanges;
        [self.currentGridAlbum configWithResult:self.currentGridAlbumResult];
        [self.gridVC refreshAlbum:self.currentGridAlbum];
        if (changes.hasIncrementalChanges) {
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
                    
                    [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                        [col moveItemAtIndexPath:[NSIndexPath indexPathForRow:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForRow:toIndex inSection:0]];
                    }];
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

-(DWAlbumGridViewController *)gridVC {
    if (!_gridVC) {
        CGFloat shortSide = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        CGFloat width = (shortSide - (_columnCount - 1) * _spacing) / _columnCount;
        _gridVC = [[DWAlbumGridViewController alloc] initWithItemWidth:width];
        _gridPhotoSize = CGSizeMake(width * 2, width * 2);
        _gridVC.selectionManager = self.selectionManager;
        __weak typeof(self) weakSelf = self;
        _gridVC.gridClickAction = ^(NSIndexPath *indexPath) {
            [weakSelf previewAtIndex:indexPath.item];
        };
        DWAlbumToolBar * toolBar = [DWAlbumToolBar toolBar];
        toolBar.sendAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.selectionManager.sendAction) {
                strongSelf.selectionManager.sendAction(strongSelf.selectionManager);
            }
        };
        
        toolBar.previewAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            PHAsset * asset = strongSelf.selectionManager.selections.firstObject.asset;
            NSInteger idx = [strongSelf.gridVC.album.fetchResult indexOfObject:asset];
            [strongSelf previewAtIndex:idx];
        };
        
        toolBar.originImageAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
           __strong typeof(weakSelf) strongSelf = weakSelf;
           strongSelf.selectionManager.useOriginImage = !strongSelf.selectionManager.useOriginImage;
           [toolBar refreshSelection];
        };
        [toolBar configWithSelectionManager:self.selectionManager];
        
        _gridVC.bottomToolBar = toolBar;
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
        _previewVC.bottomToolBar = [DWAlbumPreviewToolBar toolBar];
        DWAlbumPreviewNavigationBar * topBar = [DWAlbumPreviewNavigationBar toolBar];
        __weak typeof(self) weakSelf = self;
        topBar.retAction = ^(DWAlbumPreviewNavigationBar *toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf popViewControllerAnimated:YES];
        };
        
        topBar.selectionAction = ^(DWAlbumPreviewNavigationBar *toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf selectAtIndex:strongSelf.previewVC.currentIndex];
        };
        
        _previewVC.topToolBar = topBar;
        
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
        _selectionManager = [[DWAlbumSelectionManager alloc] initWithMaxSelectCount:self.maxSelectCount];
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

@end
