//
//  DWImagePickerController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/12.
//  Copyright © 2019 Wicky. All rights reserved.
//



#import "DWImagePickerController.h"

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

@interface DWAlbumGridViewController : UICollectionViewController<UICollectionViewDataSourcePrefetching,PHPhotoLibraryChangeObserver>

@property (nonatomic ,strong) DWAlbumModel * album;

@property (nonatomic ,strong) PHFetchResult * results;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,strong) PHCachingImageManager * imageManager;

@property (nonatomic ,assign) CGSize photoSize;

@property (nonatomic ,assign) CGSize thumnailSize;

@property (nonatomic ,assign) CGFloat velocity;

@property (nonatomic ,assign) CGFloat lastOffsetY;

@end

@implementation DWAlbumGridViewController

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.prefetchDataSource = self;
    [self.collectionView registerClass:[DWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGSize itemSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    CGFloat scale = 2;
    CGFloat thumnailScale = 0.5;
    self.photoSize = CGSizeMake(itemSize.width * scale, itemSize.height * scale);
    self.thumnailSize = CGSizeMake(itemSize.width * thumnailScale, itemSize.height * thumnailScale);
    
    CGSize contentSize = [self.collectionView.collectionViewLayout collectionViewContentSize];
    if (self.results.count) {
        if (contentSize.height > self.collectionView.bounds.size.height) {
            [self.collectionView setContentOffset:CGPointMake(0, contentSize.height - self.collectionView.bounds.size.height)];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.results.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionBottom) animated:NO];
        } else {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:(UICollectionViewScrollPositionTop) animated:NO];
        }
    }
    
}

#pragma mark --- tool method ---
-(void)configWithAlbum:(DWAlbumModel *)model albumManager:(DWAlbumManager *)albumManager {
    _album = model;
    _albumManager = albumManager;
    _results = model.fetchResult;
    self.title = model.name;
    [self.collectionView reloadData];
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

#pragma mark --- observer for Photos ---
-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails * changes = (PHFetchResultChangeDetails *)[changeInstance changeDetailsForFetchResult:self.results];
    if (!changes) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.results = changes.fetchResultAfterChanges;
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
    });
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
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView registerClass:[DWPosterCell class] forCellReuseIdentifier:@"PosterCell"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.cellHeight = 70;
    CGFloat scale = 2;
    self.photoSize = CGSizeMake(self.cellHeight * scale, self.cellHeight * scale);
}

#pragma mark --- tool method ---
-(void)configWithAlbums:(NSArray <DWAlbumModel *>*)albums albumManager:(DWAlbumManager *)albumManager gridVC:(DWAlbumGridViewController *)gridVC {
    _albums = albums;
    _albumManager = albumManager;
    _gridVC = gridVC;
    [self.tableView reloadData];
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

-(void)fetchCameraRoll {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.albumManager fetchAlbumsWithOption:self.fetchOption completion:^(DWAlbumManager * _Nullable mgr, NSArray<DWAlbumModel *> * _Nullable obj) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.listVC configWithAlbums:obj albumManager:self.albumManager gridVC:self.gridVC];
                [self.gridVC configWithAlbum:obj.firstObject albumManager:self.albumManager];
                [self setViewControllers:@[self.listVC,self.gridVC]];
            });
        }];
    });
}

#pragma mark --- tool method ---
-(void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark --- setter/getter ---
-(DWAlbumListViewController *)listVC {
    if (!_listVC) {
        _listVC = [[DWAlbumListViewController alloc] init];
        _listVC.navigationItem.title = @"照片";
        _listVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        _listVC.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
    }
    return _listVC;
}

-(DWAlbumGridViewController *)gridVC {
    if (!_gridVC) {
        UICollectionViewFlowLayout * flowlayout = [[UICollectionViewFlowLayout alloc] init];
            flowlayout.minimumLineSpacing = _spacing;
            flowlayout.minimumInteritemSpacing = _spacing;
            CGFloat width = ([UIScreen mainScreen].bounds.size.width - (_columnCount - 1) * _spacing) / _columnCount;
            flowlayout.itemSize = CGSizeMake(width, width);
            _gridVC = [[DWAlbumGridViewController alloc] initWithCollectionViewLayout:flowlayout];
    }
    return _gridVC;
}



#pragma mark --- setter/getter ---
-(DWAlbumManager *)albumManager {
    if (!_albumManager) {
        _albumManager = [[DWAlbumManager alloc] init];
    }
    return _albumManager;
}



@end
