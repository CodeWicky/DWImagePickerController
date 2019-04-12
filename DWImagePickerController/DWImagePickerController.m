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

-(void)prepareForReuse {
    [super prepareForReuse];
    self.gridImage.image = nil;
}

@end

@interface DWAlbumGridViewController : UICollectionViewController

@property (nonatomic ,strong) DWAlbumModel * album;

@property (nonatomic ,strong) PHFetchResult * results;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,assign) CGSize cellSize;

@property (nonatomic ,strong) dispatch_queue_t q;

@end

@implementation DWAlbumGridViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[DWGridCell class] forCellWithReuseIdentifier:@"cell"];
    UICollectionViewFlowLayout * layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat scale = [UIScreen mainScreen].scale;
    self.cellSize = CGSizeMake(layout.itemSize.width * scale, layout.itemSize.height * scale);
    self.q = dispatch_queue_create("dispatch_get_global_queue", DISPATCH_QUEUE_CONCURRENT);
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
    
    PHImageRequestID requestID = [self.albumManager fetchImageWithAlbum:self.album index:indexPath.row targetSize:self.cellSize progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
        if ([cell.requestLocalID isEqualToString:asset.localIdentifier]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.gridImage.image = obj.media;
            });
        } else {
            [mgr cancelRequestByID:cell.requestID];
        }
    }];
    if (cell.requestID != requestID) {
        [self.albumManager cancelRequestByID:cell.requestID];
        cell.requestID = requestID;
    }
    return cell;
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
    [self.albumManager fetchCameraRollWithOption:self.fetchOption completion:^(DWAlbumManager * _Nullable mgr, DWAlbumModel * _Nullable obj) {
        [self.colVC configWithAlbum:obj];
    }];
}

#pragma mark --- setter/getter ---
-(DWAlbumManager *)albumManager {
    if (!_albumManager) {
        _albumManager = [[DWAlbumManager alloc] init];
    }
    return _albumManager;
}

@end
