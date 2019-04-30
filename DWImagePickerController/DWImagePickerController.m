//
//  DWImagePickerController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/12.
//  Copyright © 2019 Wicky. All rights reserved.
//



#import "DWImagePickerController.h"
#import "DWImagePreviewController.h"

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

@interface DWGridCell : UICollectionViewCell

@property (nonatomic ,strong) UIImageView * gridImage;

@property (nonatomic ,copy) NSString * requestLocalID;

@end

@implementation DWGridCell

#pragma mark --- override ---
-(void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.gridImage.frame, self.bounds)) {
        self.gridImage.frame = self.bounds;
    }
}

-(void)prepareForReuse {
    [super prepareForReuse];
    self.gridImage.image = nil;
}

#pragma mark --- setter/getter ---
-(UIImageView *)gridImage {
    if (!_gridImage) {
        _gridImage = [[UIImageView alloc] initWithFrame:self.bounds];
        _gridImage.contentMode = UIViewContentModeScaleAspectFill;
        _gridImage.clipsToBounds = YES;
        [self.contentView addSubview:_gridImage];
    }
    return _gridImage;
}
@end

@interface DWAlbumGridViewController : UICollectionViewController<UICollectionViewDataSourcePrefetching,PHPhotoLibraryChangeObserver,DWImagePreviewDataSource>

@property (nonatomic ,strong) DWAlbumModel * album;

@property (nonatomic ,strong) PHFetchResult * results;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,weak) DWImagePreviewController * previewVC;

@property (nonatomic ,assign) CGSize photoSize;

@property (nonatomic ,assign) CGSize thumnailSize;

@property (nonatomic ,assign) CGFloat velocity;

@property (nonatomic ,assign) CGFloat lastOffsetY;

@property (nonatomic ,assign) BOOL firstAppear;

@property (nonatomic ,assign) BOOL needScrollToEdge;

@property (nonatomic ,strong) dispatch_queue_t preloadQueue;

@end

@implementation DWAlbumGridViewController

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.prefetchDataSource = self;
    [self.collectionView registerClass:[DWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
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

-(void)configWithPreviewVC:(DWImagePreviewController *)previewVC {
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

-(void)fetchMediaWithAsset:(PHAsset *)asset previewType:(DWImagePreviewType)previewType index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
    switch (previewType) {
        case DWImagePreviewTypeLivePhoto:
        {
            [self fetchLivePhotoWithAsset:asset index:index targetSize:targetSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
        }
            break;
        case DWImagePreviewTypeVideo:
        {
            [self fetchVideoWithIndex:index progressHandler:progressHandler fetchCompletion:fetchCompletion];
        }
            break;
        case DWImagePreviewTypeAnimateImage:
        {
            [self fetchAnimateImageWithAsset:asset index:index progressHandler:progressHandler fetchCompletion:fetchCompletion];
        }
            break;
        case DWImagePreviewTypeNone:
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

-(void)fetchLivePhotoWithAsset:(PHAsset *)asset index:(NSUInteger)index targetSize:(CGSize)targetSize progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
    
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

-(void)fetchVideoWithIndex:(NSUInteger)index progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
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

-(void)fetchAnimateImageWithAsset:(PHAsset *)asset index:(NSUInteger)index progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
    
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

-(void)fetchBigImageWithAsset:(PHAsset *)asset index:(NSUInteger)index progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
    CGFloat mediaScale = asset.pixelWidth * 1.0 / asset.pixelHeight;
    CGSize targetSize = CGSizeZero;
    if (mediaScale == 1) {
        CGFloat width = _previewVC.previewSize.width * 3;
        targetSize =  CGSizeMake(width, width);
    } else if (mediaScale > 1) {
        CGFloat width = _previewVC.previewSize.width * 3;
        targetSize = CGSizeMake(width, width / mediaScale);
    } else {
        CGFloat height = _previewVC.previewSize.height * 3;
        targetSize = CGSizeMake(height * mediaScale, height);
    }
    
    [self.albumManager fetchImageWithAlbum:self.album index:index targetSize:targetSize shouldCache:YES progress:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progress);
        }
    } completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index);
        }
    }];
}

-(void)fetchOriginImageWithIndex:(NSUInteger)index progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
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

-(DWImagePreviewType)previewTypeForAsset:(PHAsset *)asset {
    if (asset.mediaType == PHAssetMediaTypeImage) {
        if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
            return DWImagePreviewTypeLivePhoto;
        } else if ([animateExtensions() containsObject:[[[asset valueForKey:@"filename"] pathExtension] lowercaseString]]) {
            return DWImagePreviewTypeAnimateImage;
        } else {
            return DWImagePreviewTypeImage;
        }
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        return DWImagePreviewTypeVideo;
    } else {
        return DWImagePreviewTypeNone;
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
-(NSUInteger)countOfMediaForPreviewController:(DWImagePreviewController *)previewController {
    return self.results.count;
}

-(DWImagePreviewType)previewController:(DWImagePreviewController *)previewController previewTypeAtIndex:(NSUInteger)index {
    PHAsset * asset = [self.results objectAtIndex:index];
    return [self previewTypeForAsset:asset];
}

-(void)previewController:(DWImagePreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWImagePreviewType)previewType progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
    if (previewType == DWImagePreviewTypeNone) {
        if (fetchCompletion) {
            fetchCompletion(nil,index);
        }
    } else {
        PHAsset * asset = [self.results objectAtIndex:index];
        [self fetchMediaWithAsset:asset previewType:previewType index:index targetSize:previewController.previewSize progressHandler:progressHandler fetchCompletion:fetchCompletion];
    }
}

-(void)previewController:(DWImagePreviewController *)previewController fetchPosterAtIndex:(NSUInteger)index fetchCompletion:(DWImagePreviewFetchPosterCompletion)fetchCompletion {
    [self.albumManager fetchImageWithAlbum:self.album index:index targetSize:self.photoSize shouldCache:NO progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if (fetchCompletion) {
            fetchCompletion(obj.media,index,[obj satisfiedSize:previewController.previewSize]);
        }
    }];
}

-(void)previewController:(DWImagePreviewController *)previewController prefetchMediaAtIndexes:(NSArray *)indexes fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
    [indexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [obj integerValue];
        dispatch_async(self.preloadQueue, ^{
            NSLog(@"start preload %lu",index);
            PHAsset * asset = [self.results objectAtIndex:index];
            DWImagePreviewType previewType = [self previewTypeForAsset:asset];
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
    DWGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
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
                cell.gridImage.image = obj.media;
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

}

#pragma mark --- override ---
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



@end

@interface DWPosterCell : UITableViewCell

@property (nonatomic ,strong) UIImageView * posterImageView;

@property (nonatomic ,strong) UILabel * titleLabel;

@property (nonatomic ,strong) UILabel * countLabel;

@property (nonatomic ,strong) DWAlbumModel * albumModel;

@end

@implementation DWPosterCell

#pragma mark --- override ---
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    self.posterImageView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat indicatorMargin = 50;
    CGFloat labelMargin = 10;
    CGRect posterFrm = CGRectMake(0, 0, height, height);
    if (!CGRectEqualToRect(self.posterImageView.frame, posterFrm)) {
        self.posterImageView.frame = posterFrm;
    }
    
    [self.titleLabel sizeToFit];
    CGPoint origin = CGPointMake(height + labelMargin, (height - self.titleLabel.bounds.size.height) * 0.5);
    CGRect titleFrm = self.titleLabel.bounds;
    titleFrm.origin = origin;
    
    BOOL needCountLb = YES;
    if (CGRectGetMaxX(titleFrm) > width - indicatorMargin) {
        CGSize size = titleFrm.size;
        size.width = width - height - labelMargin - indicatorMargin;
        titleFrm.size = size;
        needCountLb = NO;
    } else if (CGRectGetMaxX(titleFrm) > width - indicatorMargin - labelMargin - labelMargin) {
        needCountLb = NO;
    }
    self.titleLabel.frame = titleFrm;
    
    if (needCountLb) {
        [self.countLabel sizeToFit];
        CGPoint origin = CGPointMake(CGRectGetMaxX(titleFrm) + labelMargin, (height - self.countLabel.bounds.size.height) * 0.5);
        CGRect countFrm = self.countLabel.bounds;
        countFrm.origin = origin;
        if (CGRectGetMaxX(countFrm) > width - indicatorMargin - labelMargin) {
            CGSize size = countFrm.size;
            size.width = width - origin.x - indicatorMargin - labelMargin;
            if (size.width <= 0) {
                self.countLabel.hidden = YES;
                return;
            }
            countFrm.size = size;
        }
        self.countLabel.hidden = NO;
        self.countLabel.frame = countFrm;
    } else {
        self.countLabel.hidden = YES;
    }
}

#pragma mark --- setter/getter ---
-(UIImageView *)posterImageView {
    if (!_posterImageView) {
        _posterImageView = [[UIImageView alloc] init];
        _posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        _posterImageView.clipsToBounds = YES;
        [self.contentView addSubview:_posterImageView];
    }
    return _posterImageView;
}

-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _titleLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

-(UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:17];
        _countLabel.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:_countLabel];
    }
    return _countLabel;
}

@end

@interface DWAlbumListViewController : UITableViewController

@property (nonatomic ,strong) NSArray * albums;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,weak) DWAlbumGridViewController * gridVC;

@property (nonatomic ,assign) CGFloat cellHeight;

@property (nonatomic ,assign) CGSize photoSize;

@end

@implementation DWAlbumListViewController

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerClass:[DWPosterCell class] forCellReuseIdentifier:@"PosterCell"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.cellHeight = 70;
    CGFloat scale = 2;
    self.photoSize = CGSizeMake(self.cellHeight * scale, self.cellHeight * scale);
}

#pragma mark --- tool method ---
-(void)configWithAlbums:(NSArray <DWAlbumModel *>*)albums albumManager:(DWAlbumManager *)albumManager {
    if (![_albums isEqual:albums]) {
        _albums = albums;
        [self.tableView reloadData];
    }
    if (![_albumManager isEqual:albumManager]) {
        _albumManager = albumManager;
    }
}

-(void)configWithGridVC:(DWAlbumGridViewController *)gridVC {
    if (![_gridVC isEqual:gridVC]) {
        _gridVC = gridVC;
    }
}

#pragma mark --- tableView delegate ---
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albums.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DWPosterCell * cell = [tableView dequeueReusableCellWithIdentifier:@"PosterCell" forIndexPath:indexPath];
    DWAlbumModel * albumModel = self.albums[indexPath.row];
    cell.titleLabel.text = albumModel.name;
    cell.countLabel.text = [NSString stringWithFormat:@"(%ld)",albumModel.count];
    cell.albumModel = albumModel;
    [self.albumManager fetchPostForAlbum:albumModel targetSize:self.photoSize completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if ([albumModel isEqual:cell.albumModel]) {
            cell.posterImageView.image = obj.media;
        }
    }];
    [cell setNeedsLayout];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DWAlbumModel * albumModel = self.albums[indexPath.row];
    [self.gridVC configWithAlbum:albumModel albumManager:self.albumManager];
    [self.navigationController pushViewController:self.gridVC animated:YES];
}

@end

@interface DWImagePickerController ()

@property (nonatomic ,strong) DWAlbumGridViewController * gridVC;

@property (nonatomic ,strong) DWAlbumListViewController * listVC;

@property (nonatomic ,strong) DWImagePreviewController * previewVC;

@end

@implementation DWImagePickerController
@synthesize albumManager = _albumManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

#pragma mark --- interface method ---
-(instancetype)initWithAlbumManager:(DWAlbumManager *)albumManager option:(DWAlbumFetchOption *)opt columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing {
    if (self = [super init]) {
        _albumManager = albumManager;
        _fetchOption = opt;
        _columnCount = columnCount;
        _spacing = spacing;
    }
    return self;
}

-(void)fetchCameraRollWithCompletion:(dispatch_block_t)completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.albumManager fetchAlbumsWithOption:self.fetchOption completion:^(DWAlbumManager * _Nullable mgr, NSArray<DWAlbumModel *> * _Nullable obj) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.listVC configWithAlbums:obj albumManager:self.albumManager];
                [self.gridVC configWithAlbum:obj.firstObject albumManager:self.albumManager];
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
    [imagePicker fetchCameraRollWithCompletion:^{
        [currentVC presentViewController:imagePicker animated:YES completion:nil];
    }];
    return imagePicker;
}

#pragma mark --- tool method ---
-(void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark --- setter/getter ---
-(DWAlbumListViewController *)listVC {
    if (!_listVC) {
        _listVC = [[DWAlbumListViewController alloc] init];
        [_listVC configWithGridVC:self.gridVC];
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
        DWGridFlowLayout * flowlayout = [[DWGridFlowLayout alloc] init];
        CGFloat width = ([UIScreen mainScreen].bounds.size.width - (_columnCount - 1) * _spacing) / _columnCount;
        flowlayout.itemSize = CGSizeMake(width, width);
        _gridVC = [[DWAlbumGridViewController alloc] initWithCollectionViewLayout:flowlayout];
        [_gridVC configWithPreviewVC:self.previewVC];
        self.previewVC.dataSource = _gridVC;
        _gridVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _gridVC.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
        _gridVC.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
        _gridVC.navigationItem.backBarButtonItem.tintColor = [UIColor blackColor];
    }
    return _gridVC;
}

-(DWImagePreviewController *)previewVC {
    if (!_previewVC) {
        _previewVC = [[DWImagePreviewController alloc] init];
    }
    return _previewVC;
}

#pragma mark --- setter/getter ---
-(DWAlbumManager *)albumManager {
    if (!_albumManager) {
        _albumManager = [[DWAlbumManager alloc] init];
    }
    return _albumManager;
}
@end
