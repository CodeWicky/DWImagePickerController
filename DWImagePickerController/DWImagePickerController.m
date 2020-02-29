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
#import <DWMediaPreviewController/DWMediaPreviewCell.h>
#import <DWAlbumGridController/DWAlbumMediaHelper.h>

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

@property (nonatomic ,strong) NSArray <PHAsset *>* currentPreviewResults;

@property (nonatomic ,assign) CGSize gridPhotoSize;

@property (nonatomic ,strong) dispatch_queue_t fetchMediaQueue;

@property (nonatomic ,strong) dispatch_queue_t preloadQueue;

@property (nonatomic ,strong) DWAlbumToolBar * gridBottomToolBar;

@property (nonatomic ,strong) DWAlbumPreviewNavigationBar * previewTopToolBar;

@property (nonatomic ,strong) DWAlbumPreviewToolBar * previewBottomToolBar;

@property (nonatomic ,strong) NSCache * posterCache;

@property (nonatomic ,strong) NSCache * previewDataCache;

@property (nonatomic ,assign) BOOL previewSelectionMode;

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

-(void)dismissImagePickerWithCompletion:(DWImagePickerAction)completion {
    [self dismissViewControllerAnimated:YES completion:^{
        if (completion) {
            completion(self);
        }
    }];
}

#pragma mark --- tool method ---
#pragma mark ------ 控制器相关 ------
-(void)dismissByCancel {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.pickerConf.cancelAction) {
            self.pickerConf.cancelAction(self);
        }
    }];
}

-(void)handleGridPreviewAtIndex:(NSInteger)index {
    if (index < self.currentGridModel.results.count) {
        ///刷新一下最新的资源，因为在gridVC选择的过程中，可用preview资源有可能会发生改变，所以按需刷新
        self.previewSelectionMode = NO;
        self.previewBottomToolBar.previewSelectionMode = NO;
        if ([self configCurrentPreviewResultsIfNeeded]) {
            [self.previewVC reloadPreview];
        }
        
        ///由于gridVC与previewVC资源是不一致的，所以要转换为previewVC的index
        NSInteger previewIndex = [self transformGridIndexToPreviewIndex:index];
        if (previewIndex == NSNotFound) {
            return;
        }
        [self.previewVC previewAtIndex:previewIndex];
        ///按需刷新previewVC底部的预览toolBar
        if (self.selectionManager.needsRefreshSelection) {
            [self.previewBottomToolBar refreshUI];
        }
        ///刷新previewVC顶部toolBar的选择状态
        [self setPreviewTopToolBarSelectedAtIndex:previewIndex];
        ///previewVC底部预览toolBar的focus状态刷新
        [self handlePreviewBottomToolFocusAtIndex:previewIndex];
        [self pushViewController:self.previewVC animated:YES];
    }
}

-(void)handlePreviewControllerHasChangedToIndex:(NSInteger)index {
    if (self.previewSelectionMode) {
        NSInteger selectionIndex = [self transformPreviewIndexToPreviewSelectionIndex:index];
        [self.previewTopToolBar setSelectAtIndex:selectionIndex];
        [self handlePreviewBottomToolFocusAtIndex:index];
    } else {
        NSInteger gridIndex = [self transformPreviewIndexToGridIndex:index];
        [self.gridVC notifyPreviewIndexChangeTo:gridIndex];
        [self setPreviewTopToolBarSelectedAtIndex:index];
        [self handlePreviewBottomToolFocusAtIndex:index];
    }
}

#pragma mark ------ 资源获取 ------
-(void)fetchMediaWithAsset:(PHAsset *)asset previewType:(DWMediaPreviewType)previewType index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    ///这里由于预览数据源跟album数据源存在差异（不在展示范围内的可能不会丢给预览控制器，所以要将预览控制器中的index转换成album对应的index）
    NSInteger albumIndex = [self.currentAlbum.fetchResult indexOfObject:asset];
    
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
    if (@available(iOS 9.1,*)) {
        [self.albumManager fetchLivePhotoWithAlbum:self.currentAlbum index:albumIndex targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            if (progressHandler) {
                progressHandler(progress,index);
            }
        } completion:^(DWAlbumManager * _Nullable mgr, DWLivePhotoAssetModel * _Nullable obj) {
            if (fetchCompletion && !obj.isDegraded) {
                fetchCompletion(obj.media,index);
            }
        }];
    } else {
        if (fetchCompletion) {
            fetchCompletion(nil,index);
        }
    }
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

-(void)fetchOriginPosterForVideoAsset:(PHAsset *)asset atIndex:(NSInteger)index {
    [self.albumManager fetchOriginImageWithAsset:asset networkAccessAllowed:self.currentAlbum.networkAccessAllowed progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        ///不是缩略图
        if (obj.media && !obj.isDegraded) {
            if (index < self.currentPreviewResults.count) {
                DWMediaPreviewData * data = [self.previewDataCache objectForKey:asset];
                data.previewImage = obj.media;
            }
        }
    }];
}

-(DWMediaPreviewType)previewTypeForAsset:(PHAsset *)asset {
    DWAlbumMediaOption mediaOption = [DWAlbumMediaHelper mediaOptionForAsset:asset];
    switch (mediaOption) {
        case DWAlbumMediaOptionImage:
            return DWMediaPreviewTypeImage;
        case DWAlbumMediaOptionAnimateImage:
            return DWMediaPreviewTypeAnimateImage;
        case DWAlbumMediaOptionLivePhoto:
            if (@available(iOS 9.1,*)) {
                return DWMediaPreviewTypeLivePhoto;
            }
            return DWMediaPreviewTypeImage;
        case DWAlbumMediaOptionVideo:
            return DWMediaPreviewTypeVideo;
        default:
            return DWMediaPreviewTypeNone;
    }
}

#pragma mark ------ 相册变动相关 ------
-(void)configAlbum:(DWAlbumModel *)album {
    if (![self.currentAlbum isEqual:album]) {
        self.currentAlbum = album;
        [self onCurrentAlbumChange];
        [self.gridVC configWithGridModel:self.currentGridModel];
        [self.previewVC resetOnChangeDatasource];
    }
}

-(BOOL)onCurrentAlbumChange {
    self.currentGridModel = [self gridModelFromAlbumModel:self.currentAlbum];
    return [self configCurrentPreviewResultsIfNeeded];
}

-(BOOL)configCurrentPreviewResultsIfNeeded {
    NSArray <PHAsset *>* previewResults = [self previewResutlsFromGridModel:self.currentGridModel];
    if ([self.currentPreviewResults isEqualToArray:previewResults]) {
        return NO;
    }
    [self configCurrentPreviewResults:previewResults];
    return YES;
}

-(BOOL)configPreviewSelectionResultsIfNeeded {
    NSArray <PHAsset *>* previewResults = [self previewResutlsFromSelectionsModel:self.selectionManager.selections];
    if ([self.currentPreviewResults isEqualToArray:previewResults]) {
        return NO;
    }
    [self configCurrentPreviewResults:previewResults];
    return YES;
}

-(void)configCurrentPreviewResults:(NSArray <PHAsset *>*)previewResults {
    self.currentPreviewResults = previewResults;
}

#pragma mark ------ toolBar相关 ------
-(void)handleGridBottomToolBarPreview {
    self.previewSelectionMode = YES;
    self.previewBottomToolBar.previewSelectionMode = YES;
    ///配置预览资源
    if ([self configPreviewSelectionResultsIfNeeded]) {
        [self.previewVC reloadPreview];
    }
    
    self.previewBottomToolBar.previewSelectionIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.currentPreviewResults.count)];
    ///直接预览第一个
    [self.previewVC previewAtIndex:0];
    ///按需刷新previewVC底部的预览toolBar
    if (self.selectionManager.needsRefreshSelection) {
        [self.previewBottomToolBar refreshUI];
    }
    ///刷新previewVC顶部toolBar的选择状态
    [self setPreviewTopToolBarSelectedAtIndex:0];
    ///previewVC底部预览toolBar的focus状态刷新
    [self handlePreviewBottomToolFocusAtIndex:0];
    [self pushViewController:self.previewVC animated:YES];
}

-(void)handlePreviewTopToolBarSelectAtIndex:(NSInteger)index {
    if (self.previewSelectionMode) {
        [self handlePreviewSelectionSelectAtIndex:index];
    } else {
        [self handlePreviewAlbumSelectAtIndex:index];
    }
}

-(void)handlePreviewAlbumSelectAtIndex:(NSInteger)index {
    if (index < self.currentPreviewResults.count) {
        PHAsset * asset = self.currentPreviewResults[index];
        NSInteger idx = [self.selectionManager indexOfSelection:asset];
        if (idx == NSNotFound) {
            ///这里由于gridViewController中添加的selection对应的mediaIndex是gridIndex，这里要转化成gridIndex
            NSInteger gridIndex = [self.currentGridModel.results indexOfObject:asset];
            if ([self.selectionManager addSelection:asset mediaIndex:gridIndex mediaOption:[DWAlbumMediaHelper mediaOptionForAsset:asset]]) {
                ///这里同样尽可能的为selection获取更多的复用资源
                DWAlbumSelectionModel * lastSelection = self.selectionManager.selections.lastObject;
                DWMediaPreviewData * previewData = [self.previewDataCache objectForKey:asset];
                if (previewData) {
                    ///previewData中会有全部数据，包括原始media数据及previewIamge
                    lastSelection.media = previewData.media;
                    lastSelection.previewImage = previewData.previewImage;
                }
                
                ///部分情况下，previewData中会没有previewImage，比如预加载只会获取media，导致实际加载cell时由于media存在而不再拉取poster的情况，这种情况继续寻找备援poster。首先寻找的是preview数据中加载的poster
                if (!lastSelection.previewImage) {
                    DWImageAssetModel * previewPosterCache = [self.posterCache objectForKey:asset];
                    lastSelection.previewImage = previewPosterCache.media;
                }
                
                ///如果仍然没有，最后再尝试在DWAlbumMediaHelper中寻找缓存。这部分缓存数据是给gridController进行复用的。目的是为了获取previewPoster的同时缓存给gridController。所以这里同样可以借用gridController的缓存。由于gridController中的分辨率最低，所以优先级最低。同时gridController大小刚好适中，所以也可以满足预览需求
                if (!lastSelection.previewImage) {
                    DWAlbumGridCellModel * gridModel = [DWAlbumMediaHelper posterCacheForAsset:asset];
                    lastSelection.previewImage = gridModel.media;
                }
                
                ///先设置顶部选择状态
                [self.previewTopToolBar setSelectAtIndex:self.selectionManager.selections.count];
                ///然后属性顶部和底部toolBar
                [self refreshToolBar];
                ///然后在设置底部焦点（如果先设置焦点在刷新底部会导致无法自动移至中央）
                [self.previewBottomToolBar focusOnIndex:self.selectionManager.selections.count - 1];
                ///代表是0~1，代表bottomToolBar高度改变了，要刷新cell
                if (self.previewVC.isShowing && self.selectionManager.selections.count == 1) {
                    [self.previewVC refreshCurrentPreviewLayoutWithAnimated:YES];
                    [self handleSelectOptionChangeRefreshPreviewDataSourceIfNeeded];
                }
            }
        } else {
            if ([self.selectionManager removeSelection:asset]) {
                [self.previewTopToolBar setSelectAtIndex:0];
                [self refreshToolBar];
                [self.previewBottomToolBar focusOnIndex:NSNotFound];
                ///代表是1~0，代表bottomToolBar高度改变了，要刷新cell
                if (self.previewVC.isShowing && self.selectionManager.selections.count == 0) {
                    [self.previewVC refreshCurrentPreviewLayoutWithAnimated:YES];
                    [self handleSelectOptionChangeRefreshPreviewDataSourceIfNeeded];
                }
            }
        }
    }
}

-(void)handlePreviewSelectionSelectAtIndex:(NSInteger)index {
    if (index < self.currentPreviewResults.count) {
        
        if (![self.previewBottomToolBar.previewSelectionIndexes containsIndex:index]) {
            ///恢复选择
            [self.previewBottomToolBar.previewSelectionIndexes addIndex:index];
            
            ///这里同样尽可能的为selection获取更多的复用资源
            DWAlbumSelectionModel * selection = [self.selectionManager selectionModelAtIndex:index];
            if (!selection.media || !selection.previewImage) {
                PHAsset * asset = selection.asset;
                DWMediaPreviewData * previewData = [self.previewDataCache objectForKey:asset];
                if (previewData) {
                    ///previewData中会有全部数据，包括原始media数据及previewIamge
                    selection.media = previewData.media;
                    selection.previewImage = previewData.previewImage;
                }
                
                if (!selection.previewImage) {
                    DWImageAssetModel * previewPosterCache = [self.posterCache objectForKey:asset];
                    selection.previewImage = previewPosterCache.media;
                }
                
                if (!selection.previewImage) {
                    DWAlbumGridCellModel * gridModel = [DWAlbumMediaHelper posterCacheForAsset:asset];
                    selection.previewImage = gridModel.media;
                }
            }
            
            [self.previewTopToolBar setSelectAtIndex:[self transformPreviewIndexToPreviewSelectionIndex:index]];
            [self.previewBottomToolBar refreshSelection];
        } else {
            
            [self.previewBottomToolBar.previewSelectionIndexes removeIndex:index];
            [self.previewTopToolBar setSelectAtIndex:NSNotFound];
            [self.previewBottomToolBar refreshSelection];
        }
    }
}

-(void)handlePreviewBottomToolFocusAtIndex:(NSUInteger)index {
    if (index >= self.currentPreviewResults.count) {
        [self.previewBottomToolBar focusOnIndex:NSNotFound];
    } else {
        PHAsset * asset = self.currentPreviewResults[index];
        index = [self.selectionManager indexOfSelection:asset];
        [self.previewBottomToolBar focusOnIndex:index];
    }
}

-(void)handlePreviewBottomToolBarSelectAtIndex:(NSInteger)index {
    if (self.previewSelectionMode) {
        [self.previewBottomToolBar focusOnIndex:index];
        [self.previewVC previewAtIndex:index];
        if ([self.previewBottomToolBar.previewSelectionIndexes containsIndex:index]) {
            [self.previewTopToolBar setSelectAtIndex:[self transformPreviewIndexToPreviewSelectionIndex:index]];
        } else {
            [self.previewTopToolBar setSelectAtIndex:NSNotFound];
        }
    } else {
        DWAlbumSelectionModel * selectionModel = [self.selectionManager selectionModelAtIndex:index];
        if ([self.currentPreviewResults containsObject:selectionModel.asset]) {
            [self.previewBottomToolBar focusOnIndex:index];
            ///selectionModel中记录的是gridIndex，转换成previewIndex
            NSInteger previewIndex = [self transformGridIndexToPreviewIndex:selectionModel.mediaIndex];
            [self.previewVC previewAtIndex:previewIndex];
            [self setPreviewTopToolBarSelectedAtIndex:previewIndex];
        }
    }
}

-(void)handleSelectOptionChangeRefreshPreviewDataSourceIfNeeded {
    if (!self.selectionManager.multiTypeSelectionEnable) {
        NSArray <PHAsset *>* filterResults = [self previewResutlsFromGridModel:self.currentGridModel];
        if ([filterResults isEqualToArray:self.currentPreviewResults]) {
            return;
        }
        ///这里要尽可能的保证资源刷新的过程中，previewVC当前展示的cell不变。所以记录当前展示的asset，在刷新后再切换回他的位置
        PHAsset * currentPreviewAsset = [self.currentPreviewResults objectAtIndex:self.previewVC.currentIndex];
        [self configCurrentPreviewResults:filterResults];
        NSInteger newPreviewIndex = [self.currentPreviewResults indexOfObject:currentPreviewAsset];
        [self.previewVC reloadPreview];
        [self.previewVC previewAtIndex:newPreviewIndex];
    }
}

-(void)setPreviewTopToolBarSelectedAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.currentPreviewResults objectAtIndex:index];
    NSUInteger idx = [self.selectionManager indexOfSelection:asset];
    ///调整idx。如果找不到改为0，因为navigationBar中规定0为未选中，如果找到则自加，因为规定角标从1开始
    if (idx == NSNotFound) {
        idx = 0;
    } else {
        ++ idx;
    }
    [self.previewTopToolBar setSelectAtIndex:idx];
}

-(void)refreshToolBar {
    [self.gridBottomToolBar refreshSelection];
    [self.previewBottomToolBar refreshSelection];
}

#pragma mark ------ 转换相关 ------
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

-(NSArray <PHAsset *>*)previewResutlsFromGridModel:(DWAlbumGridModel *)gridModel {
    
    ///如果可以混选且可选类型为全部的话，内部数据其实就是一样的。
    if (self.selectionManager.multiTypeSelectionEnable && self.selectionManager.selectableOption == DWAlbumMediaOptionAll) {
        return gridModel.results;
    }
    NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:gridModel.results.count];
    BOOL multiSelectionEnable = self.selectionManager.multiTypeSelectionEnable;
    DWAlbumMediaOption selectableOpt = self.selectionManager.selectableOption;
    DWAlbumMediaOption selectedOpt = self.selectionManager.selectionOption;
    [gridModel.results enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DWAlbumMediaOption mediaOpt = [DWAlbumMediaHelper mediaOptionForAsset:obj];
        ///不能选不往里面加
        if (!(selectableOpt & mediaOpt)) {
            return ;
        }
        ///如果选择了，且不是混选的话，排除掉与当前已选类型不一样的
        if ((selectedOpt != DWAlbumMediaOptionUndefine) && !multiSelectionEnable) {
            ///如果已经选择的是图片类型且当前资源为视频类型，过滤（这里不能直接 !(selectedOpt & mediaOpt) ，因为仅为图片类型这里也不符合条件）
            if ((selectedOpt & DWAlbumMediaOptionImageMask) && (mediaOpt & DWAlbumMediaOptionVideoMask)) {
                return ;
            }
            ///如果已经选择的是视频类型且当前资源为图片类型，也过滤
            if ((selectedOpt & DWAlbumMediaOptionVideoMask) && (mediaOpt & DWAlbumMediaOptionImageMask)) {
                return ;
            }
        }
        
        ///一直没过滤，那这个媒体类型就是有用得了
        [tmp addObject:obj];
    }];
    return tmp;
}

-(NSArray <PHAsset *>*)previewResutlsFromSelectionsModel:(NSArray <DWAlbumSelectionModel *>*)selectionModels {
    if (selectionModels.count == 0) {
        return nil;
    }
    NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:selectionModels.count];
    [selectionModels enumerateObjectsUsingBlock:^(DWAlbumSelectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tmp addObject:obj.asset];
    }];
    return tmp;
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

-(NSInteger)transformGridIndexToPreviewIndex:(NSInteger)index {
    if ([self.currentPreviewResults isEqualToArray:self.currentGridModel.results]) {
        return index;
    }
    PHAsset * asset = self.currentGridModel.results[index];
    return [self.currentPreviewResults indexOfObject:asset];
}

-(NSInteger)transformPreviewIndexToGridIndex:(NSInteger)index {
    if ([self.currentPreviewResults isEqualToArray:self.currentGridModel.results]) {
        return index;
    }
    PHAsset * asset = self.currentPreviewResults[index];
    return [self.currentGridModel.results indexOfObject:asset];
}

-(NSInteger)transformPreviewIndexToPreviewSelectionIndex:(NSInteger)index {
    __block NSInteger ret = NSNotFound;
    __block NSInteger findIndex = 1;
    [self.previewBottomToolBar.previewSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == index) {
            ret = findIndex;
            *stop = YES;
        } else {
            findIndex ++;
        }
    }];
    return ret;
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
    [self handleGridPreviewAtIndex:index];
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
    return self.currentPreviewResults.count;
}

-(DWMediaPreviewType)previewController:(DWMediaPreviewController *)previewController previewTypeAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.currentPreviewResults objectAtIndex:index];
    return [self previewTypeForAsset:asset];
}

-(DWMediaPreviewData *)previewController:(DWMediaPreviewController *)previewController previewDataAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.currentPreviewResults objectAtIndex:index];
    DWMediaPreviewData * previewData = [self.previewDataCache objectForKey:asset];
    return previewData;
}

-(void)previewController:(DWMediaPreviewController *)previewController finishBuildingPreviewData:(DWMediaPreviewData *)previewData atIndex:(NSUInteger)index {
    if (previewData) {
        if (index < self.currentPreviewResults.count) {
            PHAsset * asset = self.currentPreviewResults[index];
            previewData.userInfo = asset;
            [self.previewDataCache setObject:previewData forKey:asset];
        }
    }
}

-(DWMediaPreviewCell *)previewController:(DWMediaPreviewController *)previewController cellForItemAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    if (previewType != DWMediaPreviewTypeVideo) {
        return nil;
    }
    return [previewController dequeueReusablePreviewCellWithReuseIdentifier:@"videoControlCell" forIndex:index];
}

-(BOOL)previewController:(DWMediaPreviewController *)previewController isHDRAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    PHAsset * asset = [self.currentPreviewResults objectAtIndex:index];
    return asset.mediaSubtypes & PHAssetMediaSubtypePhotoHDR;
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    if (previewType == DWMediaPreviewTypeNone) {
        if (fetchCompletion) {
            fetchCompletion(nil,index);
        }
    } else {
        if (index >= self.currentPreviewResults.count) {
            if (fetchCompletion) {
                fetchCompletion(nil,index);
            }
            return ;
        }
        PHAsset * asset = [self.currentPreviewResults objectAtIndex:index];
        [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
    }
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchPosterAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType fetchCompletion:(DWMediaPreviewFetchPosterCompletion)fetchCompletion {
    if (index >= self.currentPreviewResults.count) {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
        return ;
    }
    
    PHAsset * asset = [self.currentPreviewResults objectAtIndex:index];
    if (asset.mediaType != PHAssetMediaTypeImage && asset.mediaType != PHAssetMediaTypeVideo) {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
        return ;
    }
    
    ///这里由于获取图片使用的是非缓存模式，所以单独将poster缓存维护在外部
    DWImageAssetModel * media = [self.posterCache objectForKey:asset];
    if (media) {
        if (fetchCompletion) {
            fetchCompletion(media.media,index,NO);
        }
        return;
    }
    
    ///这里获取poster不做缓存。因为poster的缓存可能会将更大分辨率的同样的asset的缓存覆盖掉
    [self.albumManager fetchImageWithAsset:asset targetSize:self.gridPhotoSize networkAccessAllowed:self.currentAlbum.networkAccessAllowed progress:nil completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
        if (obj.asset && obj.media) {
            [self.posterCache setObject:obj forKey:obj.asset];
            [DWAlbumMediaHelper cachePoster:[self gridCellModelFromImageAssetModel:obj] withAsset:obj.asset];
        }
        ///如果是为视频资源获取poster的话，尽可能要获取原图，这样会减少视频资源从poster过渡到视频资源过程中的变化
        if (previewType == DWMediaPreviewTypeVideo) {
            [self fetchOriginPosterForVideoAsset:asset atIndex:index];
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
            PHAsset * asset = [self.currentPreviewResults objectAtIndex:index];
            DWMediaPreviewType previewType = [self previewTypeForAsset:asset];
            [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:nil fetchCompletion:fetchCompletion];
        });
    }];
}

-(void)previewController:(DWMediaPreviewController *)previewController hasChangedToIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType {
    [self handlePreviewControllerHasChangedToIndex:index];
}

#pragma mark --- observer for Photos ---
-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails * changes = (PHFetchResultChangeDetails *)[changeInstance changeDetailsForFetchResult:self.currentAlbum.fetchResult];
    if (!changes) {
        return;
    }
    [self.currentAlbum configWithResult:changes.fetchResultAfterChanges];
    [self onCurrentAlbumChange];
    [self.gridVC refreshGrid:self.currentGridModel];
    dispatch_async(dispatch_get_main_queue(), ^{
        ///由于内部存在缓存机制，导致只要数据源变化了，就要重新刷新预览控制器内部数据
        [self.previewVC reloadPreview];
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
        _listVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismissByCancel)];
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
        _gridVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismissByCancel)];
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
        _previewVC.userInternalDataCache = NO;
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
        if (self.pickerConf) {
            _selectionManager = [[DWAlbumSelectionManager alloc] initWithMaxSelectCount:self.pickerConf.maxSelectCount selectableOption:self.pickerConf.selectableOption multiTypeSelectionEnable:self.pickerConf.multiTypeSelectionEnable];
            if (self.pickerConf.sendAction) {
                __weak typeof(self) weakSelf = self;
                _selectionManager.sendAction = ^(DWAlbumSelectionManager * _Nonnull mgr) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    strongSelf.pickerConf.sendAction(strongSelf);
                };
            }
        } else {
            _selectionManager = [[DWAlbumSelectionManager alloc] initWithMaxSelectCount:0 selectableOption:DWAlbumMediaOptionAll multiTypeSelectionEnable:YES];
        }
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
        if (self.pickerConf.sendAction) {
            _gridBottomToolBar.sendAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.pickerConf.sendAction(strongSelf);
            };
        }
        
        _gridBottomToolBar.previewAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf handleGridBottomToolBarPreview];
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
            if (strongSelf.previewSelectionMode) {
                NSMutableIndexSet * selectionIndexes = strongSelf.previewBottomToolBar.previewSelectionIndexes;
                NSInteger selectionIndexesCount = selectionIndexes.count;
                ///个数不相等，说明在预览模式下有减少
                if (selectionIndexesCount < strongSelf.selectionManager.selections.count) {
                    for (NSInteger i = strongSelf.selectionManager.selections.count - 1; i >= 0; --i) {
                        ///如果当前index包含，说明这个没删除
                        if ([selectionIndexes containsIndex:i]) {
                            continue;
                        }
                        ///如果不包含，删除
                        [strongSelf.selectionManager removeSelectionAtIndex:i];
                        ///如果删除完成的时候，个数一样了，则说明删除完了，停止循环
                        if (strongSelf.selectionManager.selections.count == selectionIndexesCount) {
                            break;
                        }
                    }
                    strongSelf.previewSelectionMode = NO;
                    strongSelf.previewBottomToolBar.previewSelectionMode = NO;
                    strongSelf.previewBottomToolBar.previewSelectionIndexes = nil;
                    ///这里先不标记，还要刷新gridViewController
                    if (strongSelf.selectionManager.needsRefreshSelection) {
                        [strongSelf.gridBottomToolBar refreshSelection];
                    }
                }
                
            }
            [strongSelf popViewControllerAnimated:YES];
        };
        _previewTopToolBar.selectionAction = ^(DWAlbumPreviewNavigationBar *toolBar) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf handlePreviewTopToolBarSelectAtIndex:strongSelf.previewVC.currentIndex];
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
            [strongSelf handlePreviewBottomToolBarSelectAtIndex:index];
        };
        if (self.pickerConf.sendAction) {
            _previewBottomToolBar.sendAction = ^(DWAlbumToolBar * _Nonnull toolBar) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.pickerConf.sendAction(strongSelf);
            };
        }
        
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

-(NSCache *)previewDataCache {
    if (!_previewDataCache) {
        _previewDataCache = [[NSCache alloc] init];
    }
    return _previewDataCache;
}

@end

@implementation DWImagePickerConfiguration

-(instancetype)init {
    if (self = [super init]) {
        _displayMediaOption = DWAlbumMediaOptionAll;
        _selectableOption = DWAlbumMediaOptionAll;
        _maxSelectCount = 0;
        _multiTypeSelectionEnable = YES;
    }
    return self;
}

@end
