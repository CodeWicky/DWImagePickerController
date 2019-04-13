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

@property (nonatomic ,assign) PHImageRequestID requestID;

@end

@implementation DWGridCell

-(instancetype)init {
    if (self = [super init]) {
        _requestID = PHInvalidImageRequestID;
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.gridImage.frame, self.bounds)) {
        self.gridImage.frame = self.bounds;
    }
}

-(UIImageView *)gridImage {
    if (!_gridImage) {
        _gridImage = [[UIImageView alloc] initWithFrame:self.bounds];
        _gridImage.contentMode = UIViewContentModeScaleAspectFill;
        _gridImage.clipsToBounds = YES;
        [self.contentView addSubview:_gridImage];
    }
    return _gridImage;
}

//-(void)prepareForReuse {
//    [super prepareForReuse];
//    self.gridImage.image = nil;
//}

@end

@interface DWAlbumGridViewController : UICollectionViewController<UICollectionViewDataSourcePrefetching>

@property (nonatomic ,strong) DWAlbumModel * album;

@property (nonatomic ,strong) PHFetchResult * results;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,assign) CGSize photoSize;

@property (nonatomic ,assign) CGRect previousPreheatRect;

@end

@implementation DWAlbumGridViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[DWGridCell class] forCellWithReuseIdentifier:@"cell"];
    UICollectionViewFlowLayout * layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat scale = 2;
    self.photoSize = CGSizeMake(layout.itemSize.width * scale, layout.itemSize.height * scale);
}

-(void)configWithAlbum:(DWAlbumModel *)model {
    _album = model;
    _results = model.fetchResult;
    self.title = model.name;
    [self.collectionView reloadData];
}

#pragma mark --- col delegate ---
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.results.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DWGridCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    PHAsset * asset = [self.results objectAtIndex:indexPath.row];
    cell.requestLocalID = asset.localIdentifier;
    
    PHImageRequestID requestID = [self.albumManager fetchImageWithAsset:asset targetSize:self.photoSize networkAccessAllowed:NO progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if (!obj) {
            cell.gridImage.image = nil;
        } else {
            if ([cell.requestLocalID isEqualToString:obj.asset.localIdentifier]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.gridImage.image = obj.media;
                });
            } else {
                [mgr cancelRequestByID:cell.requestID];
            }
        }
    }];

    if (cell.requestID != requestID) {
        [self.albumManager cancelRequestByID:cell.requestID];
        cell.requestID = requestID;
    }
    return cell;
}

#pragma mark --- tool method ---
-(void)resetCachedAssets {
    [self.albumManager stopCachingAllImages];
    self.previousPreheatRect = CGRectZero;
}

-(void)updateCacheAssets {
    
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    
    CGRect visibleRect = CGRectMake(self.collectionView.contentOffset.x, self.collectionView.contentOffset.y, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta <= self.view.bounds.size.height / 3) {
        return;
    }
    
    
}

@end



@interface DWImagePickerController ()

@property (nonatomic ,strong) DWAlbumGridViewController * colVC;

@end

@implementation DWImagePickerController
@synthesize albumManager = _albumManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

#pragma mark --- interface method ---
-(instancetype)initWithAlbumManager:(DWAlbumManager *)albumManager option:(DWAlbumFetchOption *)opt columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing {
    UICollectionViewFlowLayout * flowlayout = [[UICollectionViewFlowLayout alloc] init];
    flowlayout.minimumLineSpacing = spacing;
    flowlayout.minimumInteritemSpacing = spacing;
    CGFloat width = ([UIScreen mainScreen].bounds.size.width - (columnCount - 1) * spacing) / columnCount;
    flowlayout.itemSize = CGSizeMake(width, width);
    DWAlbumGridViewController * grid = [[DWAlbumGridViewController alloc] initWithCollectionViewLayout:flowlayout];
    if (self = [super initWithRootViewController:grid]) {
        _albumManager = albumManager;
        _fetchOption = opt;
        _columnCount = columnCount;
        _colVC = grid;
    }
    return self;
}

-(void)fetchCameraRoll {
    self.colVC.albumManager = self.albumManager;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.albumManager fetchCameraRollWithOption:self.fetchOption completion:^(DWAlbumManager * _Nullable mgr, DWAlbumModel * _Nullable obj) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.colVC configWithAlbum:obj];
            });
        }];
    });
}

#pragma mark --- setter/getter ---
-(DWAlbumManager *)albumManager {
    if (!_albumManager) {
        _albumManager = [[DWAlbumManager alloc] init];
    }
    return _albumManager;
}

@end
