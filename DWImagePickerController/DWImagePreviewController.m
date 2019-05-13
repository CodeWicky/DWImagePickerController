//
//  DWImagePreviewController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePreviewController.h"
#import "DWImagePreviewCell.h"

@interface DWImagePreviewCell ()

-(void)configIndex:(NSUInteger)index;

@end

@interface DWImagePreviewLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) CGFloat distanceBetweenPages;

@end

@implementation DWImagePreviewLayout

#pragma mark --- override ---
- (instancetype)init {
    self = [super init];
    if (self) {
        self.distanceBetweenPages = 20;
    }
    return self;
}

-(void)prepareLayout {
    [super prepareLayout];
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.itemSize = [UIScreen mainScreen].bounds.size;
}

///重写attr来在miniLineSpacing为0的情况下cell之间也有间距（如果设置miniLineSpacing不为0的时候，即使在全屏cell的情况下，滚动一次，collectionView也会加载两个cell）
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttsArray = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
    CGFloat halfWidth = self.collectionView.bounds.size.width / 2.0;
    CGFloat centerX = self.collectionView.contentOffset.x + halfWidth;
    [layoutAttsArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.center = CGPointMake(obj.center.x + (obj.center.x - centerX) / halfWidth * self.distanceBetweenPages / 2, obj.center.y);
    }];
    return layoutAttsArray;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end

@interface DWImagePreviewData : NSObject

@property (nonatomic ,strong) UIImage * previewImage;

@property (nonatomic ,strong) id media;

@property (nonatomic ,strong) YYImage * animateImage;

@property (nonatomic ,assign) DWImagePreviewType previewType;

@end

@implementation DWImagePreviewData

@end

@interface DWImagePreviewController ()

@property (nonatomic ,assign) NSInteger index;

@property (nonatomic ,assign) BOOL indexChanged;

@property (nonatomic ,assign) BOOL sourceInteractivePopGestureEnabled;

@property (nonatomic ,assign) BOOL navigationBarShouldHidden;

@property (nonatomic ,strong) NSCache * dataCache;

@end

@interface DWImagePreviewController ()

@property (nonatomic ,strong) dispatch_queue_t asyncDecodeQueue;

@end

@implementation DWImagePreviewController

static NSString * const normalImageID = @"DWNormalImagePreviewCell";
static NSString * const animateImageID = @"DWAnimateImagePreviewCell";
static NSString * const livePhotoID = @"DWLivePhotoPreviewCell";
static NSString * const videoImageID = @"DWVideoPreviewCell";

#pragma mark --- interface method ---
-(void)previewAtIndex:(NSUInteger)index {
    if (index != _index && index < [self collectionView:self.collectionView numberOfItemsInSection:0]) {
        _index = index;
        _indexChanged = YES;
    }
}

-(void)photoCountHasChanged {
    [self.collectionView reloadData];
}

-(void)clearCache {
    [self.dataCache removeAllObjects];
}

-(void)resetOnChangeDatasource {
    [self clearCache];
    [self photoCountHasChanged];
}

#pragma mark --- tool method ---
-(void)showPreview {
    if (_indexChanged) {
        ///如果预览位置发生改变则滚动到该位置
        _indexChanged = NO;
        DWImagePreviewLayout * layout = (DWImagePreviewLayout *)self.collectionViewLayout;
        CGFloat offset_x = _index * (layout.itemSize.width + layout.minimumLineSpacing);
        [self.collectionView setContentOffset:CGPointMake(offset_x, 0)];
    } else {
        ///disappear时会释放当前cell的资源，故如果不改变位置的话，需要刷新当前cell
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:_index inSection:0];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    self.navigationBarShouldHidden = self.navigationController.isNavigationBarHidden;
    [self setToolBarHidden:NO];
}

-(void)clearPreview {
    DWImagePreviewCell * cell = (DWImagePreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0]];
    [cell clearCell];
    [self turnToDarkBackground:NO];
}

-(void)setToolBarHidden:(BOOL)hidden {
    if (_isToolBarShowing == hidden) {
        [self.navigationController setNavigationBarHidden:hidden animated:YES];
        [self turnToDarkBackground:hidden];
        _isToolBarShowing = !hidden;
    }
}

-(DWImagePreviewData *)dataAtIndex:(NSUInteger)index {
    ///获取数据模型，如果不存在则创建并缓存
    DWImagePreviewData * data = [self.dataCache objectForKey:@(index)];
    if (!data) {
        data = [[DWImagePreviewData alloc] init];
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:previewTypeAtIndex:)]) {
            data.previewType = [self.dataSource previewController:self previewTypeAtIndex:index];
        }
        [self.dataCache setObject:data forKey:@(index)];
    }
    return data;
}

-(void)previewDidChangedToIndex:(UIScrollView *)scrollView {
    NSInteger page = (scrollView.contentOffset.x + _previewSize.width / 2) / _previewSize.width;
    _index = page;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:hasChangedToIndex:)]) {
        [self.dataSource previewController:self hasChangedToIndex:page];
    }
}

-(void)configActionForCell:(DWImagePreviewCell *)cell indexPath:(NSIndexPath *)indexPath {
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
    
    cell.callNavigationHide = ^(DWImagePreviewCell * _Nonnull cell ,BOOL hide) {
        __strong typeof(weakSelf)StrongSelf = weakSelf;
        [StrongSelf setToolBarHidden:hide];
    };
}

-(void)turnToDarkBackground:(BOOL)dark {
    [UIView animateWithDuration:0.2 animations:^{
        self.collectionView.backgroundColor = [UIColor colorWithWhite:dark?0:1 alpha:1];
    }];
}

-(void)fetchPosterAtIndex:(NSUInteger)index previewType:(DWImagePreviewType)previewType fetchCompletion:(DWImagePreviewFetchPosterCompletion)fetchCompletion {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:fetchPosterAtIndex:fetchCompletion:)]) {
        [self.dataSource previewController:self fetchPosterAtIndex:index fetchCompletion:fetchCompletion];
    } else {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
    }
}

-(void)fetchMediaAtIndex:(NSUInteger)index previewType:(DWImagePreviewType)previewType progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:fetchMediaAtIndex:previewType:progressHandler:fetchCompletion:)]) {
        [self.dataSource previewController:self fetchMediaAtIndex:index previewType:previewType progressHandler:progressHandler fetchCompletion:fetchCompletion];
    } else {
        if (fetchCompletion) {
            fetchCompletion(nil,NO);
        }
    }
}

-(void)configPosterAndFetchMediaWithCellData:(DWImagePreviewData *)cellData cell:(DWImagePreviewCell *)cell previewType:(DWImagePreviewType)previewType index:(NSUInteger)index satisfiedSize:(BOOL)satisfiedSize {
    NSUInteger originIndex = index;
    cell.poster = cellData.previewImage;
    if (previewType == DWImagePreviewTypeImage && satisfiedSize) {
        cellData.media = cellData.previewImage;
        return;
    }
    [self fetchMediaAtIndex:originIndex previewType:previewType progressHandler:^(CGFloat progressNum) {
        NSLog(@"progress = %f",progressNum);
    } fetchCompletion:^(id  _Nullable media, NSUInteger index) {
        [self configMedia:media forCellData:cellData asynchronous:YES completion:^{
            if (index == cell.index) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.media = cellData.media;
                });
            }
        }];
    }];
}

-(void)configMedia:(id)media forCellData:(DWImagePreviewData *)cellData asynchronous:(BOOL)asynchronous completion:(dispatch_block_t)completion {
    if (cellData.previewType == DWImagePreviewTypeAnimateImage) {
        dispatch_block_t decodeAction = ^(){
            YYImage * image = nil;
            if (media) {
                image = [[YYImage alloc] initWithData:media];
            }
            cellData.media = image;
            if (completion) {
                completion();
            }
        };
        if (asynchronous) {
            dispatch_async(self.asyncDecodeQueue, decodeAction);
        } else {
            decodeAction();
        }
    } else {
        cellData.media = media;
        if (completion) {
            completion();
        }
    }
}

-(void)prefetchMediaForCollection:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:prefetchMediaAtIndexes:fetchCompletion:)]) {
        NSMutableArray * indexes = [NSMutableArray arrayWithCapacity:4];
        NSInteger count = [self collectionView:collectionView numberOfItemsInSection:0];
        NSUInteger prefetchCount = _prefetchCount;
        for (NSInteger i = indexPath.row,step = 0,target = 0; step > -prefetchCount;) {
            if (step > 0) {
                step = -step;
            } else {
                step = -step + 1;
            }
            
            target = i + step;
            if (target < 0 || target >= count) {
                continue;
            }
            
            DWImagePreviewData * data = [self dataAtIndex:target];
            if (data.media) {
                continue;
            }
            [indexes addObject:@(target)];
        }
        if (indexes.count) {
            [self.dataSource previewController:self prefetchMediaAtIndexes:indexes fetchCompletion:^(id  _Nullable media, NSUInteger index) {
                NSLog(@"preload complete %lu",index);
                DWImagePreviewData * cellData = [self dataAtIndex:index];
                [self configMedia:media forCellData:cellData asynchronous:YES completion:nil];
            }];
        }
    }
}

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[DWNormalImagePreviewCell class] forCellWithReuseIdentifier:normalImageID];
    [self.collectionView registerClass:[DWAnimateImagePreviewCell class] forCellWithReuseIdentifier:animateImageID];
    [self.collectionView registerClass:[DWLivePhotoPreviewCell class] forCellWithReuseIdentifier:livePhotoID];
    [self.collectionView registerClass:[DWVideoPreviewCell class] forCellWithReuseIdentifier:videoImageID];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showPreview];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    ///按需关闭侧滑返回
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.sourceInteractivePopGestureEnabled = self.navigationController.interactivePopGestureRecognizer.enabled;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    ///恢复侧滑返回
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = self.sourceInteractivePopGestureEnabled;
    }
    [self.navigationController setNavigationBarHidden:self.navigationBarShouldHidden animated:YES];
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
    
    NSInteger originIndex = indexPath.item;
    NSLog(@"cell for row %ld",originIndex);
    DWImagePreviewData * cellData = [self dataAtIndex:originIndex];
    DWImagePreviewType previewType = cellData.previewType;
    __kindof DWImagePreviewCell * cell;
    switch (previewType) {
        case DWImagePreviewTypeAnimateImage:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:animateImageID forIndexPath:indexPath];
        }
            break;
        case DWImagePreviewTypeLivePhoto:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:livePhotoID forIndexPath:indexPath];
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
    
    if (previewType == DWImagePreviewTypeImage || previewType == DWImagePreviewTypeLivePhoto) {
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:isHDRAtIndex:)]) {
            ((DWNormalImagePreviewCell *)cell).isHDR = [self.dataSource previewController:self isHDRAtIndex:originIndex];
        }
    }
    
    
    [cell configIndex:originIndex];
    if (previewType != DWImagePreviewTypeNone) {
        [self configActionForCell:cell indexPath:indexPath];
        [cell configCollectionViewController:self];
    }
    if (cellData.media) {
        cell.media = cellData.media;
    } else if (cellData.previewImage) {
        [self configPosterAndFetchMediaWithCellData:cellData cell:cell previewType:previewType index:originIndex satisfiedSize:NO];
    } else {
        [self fetchPosterAtIndex:originIndex previewType:previewType fetchCompletion:^(id  _Nullable media, NSUInteger index, BOOL satisfiedSize) {
            cellData.previewImage = media;
            if (index == cell.index) {
                [self configPosterAndFetchMediaWithCellData:cellData cell:cell previewType:previewType index:originIndex satisfiedSize:satisfiedSize];
            }
        }];
    }
    
    [self prefetchMediaForCollection:collectionView indexPath:indexPath];
    
    return cell;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self previewDidChangedToIndex:scrollView];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self previewDidChangedToIndex:scrollView];
    }
}

#pragma mark --- screen rotate ---
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    _previewSize = size;
}

#pragma mark --- override ---
-(instancetype)init {
    DWImagePreviewLayout * layout = [[DWImagePreviewLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.distanceBetweenPages = 40;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.itemSize = [UIScreen mainScreen].bounds.size;
    if (self = [self initWithCollectionViewLayout:layout]) {
        _index = -1;
        _cacheCount = 10;
        _prefetchCount = 2;
        _previewSize = [UIScreen mainScreen].bounds.size;
        _isToolBarShowing = YES;
        _closeOnSlidingDown = YES;
        self.collectionView.pagingEnabled = YES;
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
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

#pragma mark --- setter/getter ---
-(NSCache *)dataCache {
    if (!_dataCache) {
        _dataCache = [[NSCache alloc] init];
        _dataCache.countLimit = _cacheCount;
    }
    return _dataCache;
}

-(dispatch_queue_t)asyncDecodeQueue {
    if (!_asyncDecodeQueue) {
        _asyncDecodeQueue = dispatch_queue_create("com.wicky.dwimagepreviewcontroller", DISPATCH_QUEUE_CONCURRENT);
    }
    return _asyncDecodeQueue;
}

@end
