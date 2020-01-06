//
//  DWAlbumGridViewController.m
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import "DWAlbumGridViewController.h"
#import <DWMediaPreviewController/DWFixAdjustCollectionView.h>
#import "DWAlbumGridCell.h"

@interface DWAlbumModel ()

-(void)configWithResult:(PHFetchResult *)result;

@end

@interface DWGridFlowLayout : UICollectionViewFlowLayout

@end

@implementation DWGridFlowLayout

-(void)prepareLayout {
    [super prepareLayout];
    CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat sizeWidth = self.itemSize.width;
    NSInteger column = (NSInteger)(viewWidth / sizeWidth);
    if (column == 1) {
        self.minimumLineSpacing = self.minimumInteritemSpacing = 1 / MIN(2, [UIScreen mainScreen].scale);
    } else {
        self.minimumLineSpacing = self.minimumInteritemSpacing = (viewWidth - sizeWidth * column) / (column - 1) - __FLT_EPSILON__;
    }
}

@end

@interface DWAlbumGridViewController ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource,UICollectionViewDataSourcePrefetching,PHPhotoLibraryChangeObserver>

@property (nonatomic ,strong) DWFixAdjustCollectionView * collectionView;

@property (nonatomic ,strong) DWGridFlowLayout * collectionViewLayout;

@property (nonatomic ,strong) DWAlbumModel * album;

@property (nonatomic ,strong) PHFetchResult * results;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,weak) DWMediaPreviewController * previewVC;

@property (nonatomic ,assign) CGSize photoSize;

@property (nonatomic ,assign) CGSize thumnailSize;

@property (nonatomic ,assign) CGFloat velocity;

@property (nonatomic ,assign) CGFloat lastOffsetY;

@property (nonatomic ,assign) BOOL firstAppear;

@property (nonatomic ,assign) BOOL needScrollToEdge;

@property (nonatomic ,strong) dispatch_queue_t preloadQueue;

@property (nonatomic ,strong) Class cellClazz;

@end

@implementation DWAlbumGridViewController

#pragma mark --- interface method ---
-(instancetype)initWithItemWidth:(CGFloat)width {
    if (self = [super init]) {
        _itemWidth = width;
    }
    return self;
}

-(void)registGridCell:(Class)cellClazz {
    self.cellClazz = cellClazz;
}

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    [self.view addSubview:self.collectionView];
    if (self.bottomToolBar) {
        [self.view addSubview:self.bottomToolBar];
        UIEdgeInsets insets = self.collectionView.contentInset;
        insets.bottom += self.bottomToolBar.toolBarHeight;
        self.collectionView.contentInset = insets;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    if (@available(iOS 10.0,*)) {
        self.collectionView.prefetchDataSource = self;
    }
    self.firstAppear = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.firstAppear) {
        CGSize itemSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
        CGFloat scale = 2;
        CGFloat thumnailScale = 0.5;
        self.photoSize = CGSizeMake(floor(itemSize.width * scale), floor(itemSize.height * scale));
        self.thumnailSize = CGSizeMake(floor(itemSize.width * thumnailScale), floor(itemSize.height * thumnailScale));
    }
    
    
    if (self.needScrollToEdge && self.results.count) {
        CGSize contentSize = [self.collectionView.collectionViewLayout collectionViewContentSize];
        if (contentSize.height > self.collectionView.bounds.size.height) {
            [self.collectionView setContentOffset:CGPointMake(0, contentSize.height - self.collectionView.bounds.size.height)];
            if (self.firstAppear) {
                ///防止第一次进入时，无法滚动至底部（差20px）
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.results.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionBottom) animated:NO];
                });
            } else {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.results.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionBottom) animated:NO];
            }
        } else {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:(UICollectionViewScrollPositionTop) animated:NO];
        }
    }
    self.firstAppear = NO;
    self.needScrollToEdge = NO;
}

#pragma mark --- tool method ---
-(void)configWithAlbum:(DWAlbumModel *)model albumManager:(DWAlbumManager *)albumManager {
    if (![_album isEqual:model]) {
        _album = model;
        _results = model.fetchResult;
        self.title = model.name;
        _needScrollToEdge = YES;
        [self.collectionView reloadData];
        [_previewVC resetOnChangeDatasource];
    }
    if (![_albumManager isEqual:albumManager]) {
        _albumManager = albumManager;
    }
}

-(void)configWithPreviewVC:(DWMediaPreviewController *)previewVC {
    if (![_previewVC isEqual:previewVC]) {
        _previewVC = previewVC;
    }
}

-(void)loadRealPhoto {
    CGRect visibleRect = (CGRect){self.collectionView.contentOffset,self.collectionView.bounds.size};
    NSArray <UICollectionViewLayoutAttributes *>* attrs = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:visibleRect];
    NSMutableArray * indexPaths = [NSMutableArray arrayWithCapacity:attrs.count];
    for (UICollectionViewLayoutAttributes * obj in attrs) {
        [indexPaths addObject:obj.indexPath];
    }
    
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

-(void)fetchMediaWithAsset:(PHAsset *)asset previewType:(DWMediaPreviewType)previewType index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
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
}

-(void)fetchLivePhotoWithAsset:(PHAsset *)asset index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    
    [self.albumManager fetchLivePhotoWithAlbum:self.album index:index targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progress);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWLivePhotoAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchVideoWithIndex:(NSUInteger)index progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    [self.albumManager fetchVideoWithAlbum:self.album index:index shouldCache:YES progrss:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWVideoAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchAnimateImageWithAsset:(PHAsset *)asset index:(NSUInteger)index progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    
    [self.albumManager fetchOriginImageDataWithAlbum:self.album index:index progress:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum);
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
    
    [self.albumManager fetchImageWithAlbum:self.album index:index targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progress);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        ///由于指定尺寸，所有亦可能有缩略图尺寸，如果是缩略图的话，不设置图片，已经有封面了
        if (fetchCompletion && !obj.isDegraded) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchOriginImageWithIndex:(NSUInteger)index progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    [self.albumManager fetchOriginImageWithAlbum:self.album index:index progress:^(double progressNum, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progressNum);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(DWMediaPreviewType)previewTypeForAsset:(PHAsset *)asset {
    if (asset.mediaType == PHAssetMediaTypeImage) {
        if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
            return DWMediaPreviewTypeLivePhoto;
        } else if ([animateExtensions() containsObject:[[[asset valueForKey:@"filename"] pathExtension] lowercaseString]]) {
            return DWMediaPreviewTypeAnimateImage;
        } else {
            return DWMediaPreviewTypeImage;
        }
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        return DWMediaPreviewTypeVideo;
    } else {
        return DWMediaPreviewTypeNone;
    }
}

#pragma mark --- tool func ---
NS_INLINE NSArray * animateExtensions() {
    static NSArray * exts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exts = @[@"webp",@"gif",@"apng"];
    });
    return exts;
}

#pragma mark --- observer for Photos ---
-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails * changes = (PHFetchResultChangeDetails *)[changeInstance changeDetailsForFetchResult:self.results];
    if (!changes) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.results = changes.fetchResultAfterChanges;
        [self.album configWithResult:self.results];
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
            [self.collectionView reloadData];
        }
    });
}

#pragma mark --- previewController delegate ---
-(NSUInteger)countOfMediaForPreviewController:(DWMediaPreviewController *)previewController {
    return self.results.count;
}

-(DWMediaPreviewType)previewController:(DWMediaPreviewController *)previewController previewTypeAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.results objectAtIndex:index];
    return [self previewTypeForAsset:asset];
}

-(BOOL)previewController:(DWMediaPreviewController *)previewController isHDRAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.results objectAtIndex:index];
    return asset.mediaSubtypes & PHAssetMediaSubtypePhotoHDR;
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    if (previewType == DWMediaPreviewTypeNone) {
        if (fetchCompletion) {
            fetchCompletion(nil,index);
        }
    } else {
        PHAsset * asset = [self.results objectAtIndex:index];
        [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
    }
}

-(void)previewController:(DWMediaPreviewController *)previewController fetchPosterAtIndex:(NSUInteger)index fetchCompletion:(DWMediaPreviewFetchPosterCompletion)fetchCompletion {
    [self.albumManager fetchImageWithAlbum:self.album index:index targetSize:self.photoSize shouldCache:NO progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
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
            PHAsset * asset = [self.results objectAtIndex:index];
            DWMediaPreviewType previewType = [self previewTypeForAsset:asset];
            [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:nil fetchCompletion:fetchCompletion];
        });
    }];
}

#pragma mark --- collectionView delegate ---
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.results.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset * asset = [self.results objectAtIndex:indexPath.row];
    DWAlbumGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
    cell.requestLocalID = asset.localIdentifier;
    
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
    
    [self.albumManager fetchImageWithAlbum:self.album index:indexPath.row targetSize:targetSize shouldCache:!thumnail progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if ([cell.requestLocalID isEqualToString:asset.localIdentifier]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.model = obj;
                [cell setSelectAtIndex:12];
            });
        }
    }];
    [cell setNeedsLayout];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.previewVC previewAtIndex:indexPath.row];
    [self.navigationController pushViewController:self.previewVC animated:YES];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.velocity = fabs(scrollView.contentOffset.y - self.lastOffsetY);
    self.lastOffsetY = scrollView.contentOffset.y;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadRealPhoto];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadRealPhoto];
    }
}

-(void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableIndexSet * indexes = [NSMutableIndexSet indexSet];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [indexes addIndex:obj.row];
    }];
    [self.albumManager startCachingImagesForAlbum:self.album indexes:indexes targetSize:self.photoSize];
}

-(void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableIndexSet * indexes = [NSMutableIndexSet indexSet];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [indexes addIndex:obj.row];
    }];
    [self.albumManager stopCachingImagesForAlbum:self.album indexes:indexes targetSize:self.photoSize];
}

#pragma mark --- rotate delegate ---
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.collectionView.dw_autoFixContentOffset = YES;
}

-(void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    UIEdgeInsets insets = self.collectionView.contentInset;
    insets.left = self.view.safeAreaInsets.left;
    insets.right = self.view.safeAreaInsets.right;
    self.collectionView.contentInset = insets;
    self.collectionView.frame = self.view.frame;
}

#pragma mark --- override ---
//-(void)loadView {
//    [super loadView];
//    self.view = self.collectionView;
//}

-(void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark --- setter/getter ---
-(dispatch_queue_t)preloadQueue {
    if (!_preloadQueue) {
        _preloadQueue = dispatch_queue_create("com.wicky.dwimagepicker", DISPATCH_QUEUE_CONCURRENT);
    }
    return _preloadQueue;
}

-(DWGridFlowLayout *)collectionViewLayout {
    if (!_collectionViewLayout) {
        _collectionViewLayout = [[DWGridFlowLayout alloc] init];
        _collectionViewLayout.itemSize = CGSizeMake(self.itemWidth, self.itemWidth);
    }
    return _collectionViewLayout;
}

-(DWFixAdjustCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[DWFixAdjustCollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:self.collectionViewLayout];
        Class cls = self.cellClazz?:[DWAlbumGridCell class];
        [self.collectionView registerClass:cls forCellWithReuseIdentifier:@"GridCell"];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsVerticalScrollIndicator = NO;
    }
    return _collectionView;
}

@end
