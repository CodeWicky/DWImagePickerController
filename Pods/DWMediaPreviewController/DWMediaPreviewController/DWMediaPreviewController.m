//
//  DWMediaPreviewController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWMediaPreviewController.h"
#import "DWMediaPreviewCell.h"

@interface DWMediaPreviewCell ()

-(void)configIndex:(NSUInteger)index;

@end

@interface DWMediaPreviewLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) CGFloat distanceBetweenPages;

@end

@implementation DWMediaPreviewLayout

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

@interface DWMediaPreviewData : NSObject

@property (nonatomic ,strong) UIImage * previewImage;

@property (nonatomic ,strong) id media;

@property (nonatomic ,strong) YYImage * animateImage;

@property (nonatomic ,assign) DWMediaPreviewType previewType;

@property (nonatomic ,assign) BOOL isHDR;

@end

@implementation DWMediaPreviewData

@end

@interface DWMediaPreviewController ()

@property (nonatomic ,assign) NSInteger index;

@property (nonatomic ,assign) BOOL indexChanged;

@property (nonatomic ,assign) BOOL sourceInteractivePopGestureEnabled;

@property (nonatomic ,assign) BOOL navigationBarShouldHidden;

@property (nonatomic ,strong) NSCache * dataCache;

@property (nonatomic ,strong) dispatch_queue_t asyncDecodeQueue;

@property (nonatomic ,assign) BOOL firstCellGotFocus;

@end

@implementation DWMediaPreviewController

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
        DWMediaPreviewLayout * layout = (DWMediaPreviewLayout *)self.collectionViewLayout;
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
    DWMediaPreviewCell * cell = (DWMediaPreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0]];
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

-(DWMediaPreviewData *)dataAtIndex:(NSUInteger)index {
    ///获取数据模型，如果不存在则创建并缓存
    DWMediaPreviewData * data = [self.dataCache objectForKey:@(index)];
    if (!data) {
        data = [[DWMediaPreviewData alloc] init];
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:previewTypeAtIndex:)]) {
            data.previewType = [self.dataSource previewController:self previewTypeAtIndex:index];
        }
        
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:isHDRAtIndex:)]) {
            data.isHDR = [self.dataSource previewController:self isHDRAtIndex:index];
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

-(void)configActionForCell:(DWMediaPreviewCell *)cell indexPath:(NSIndexPath *)indexPath {
    __weak typeof(self)weakSelf = self;
    cell.tapAction = ^(DWMediaPreviewCell * _Nonnull cell) {
        __strong typeof(weakSelf)StrongSelf = weakSelf;
        [StrongSelf setToolBarHidden:StrongSelf.isToolBarShowing];
    };
    
    cell.doubleClickAction = ^(DWMediaPreviewCell * _Nonnull cell ,CGPoint point) {
        __strong typeof(weakSelf)StrongSelf = weakSelf;
        if (StrongSelf.isToolBarShowing) {
            [StrongSelf setToolBarHidden:YES];
        }
        [cell zoomMediaView:!cell.zooming point:point];
    };
    
    cell.callNavigationHide = ^(DWMediaPreviewCell * _Nonnull cell ,BOOL hide) {
        __strong typeof(weakSelf)StrongSelf = weakSelf;
        [StrongSelf setToolBarHidden:hide];
    };
}

-(void)turnToDarkBackground:(BOOL)dark {
    [UIView animateWithDuration:0.2 animations:^{
        self.collectionView.backgroundColor = [UIColor colorWithWhite:dark?0:1 alpha:1];
    }];
}

-(void)fetchPosterAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType fetchCompletion:(DWMediaPreviewFetchPosterCompletion)fetchCompletion {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:fetchPosterAtIndex:fetchCompletion:)]) {
        [self.dataSource previewController:self fetchPosterAtIndex:index fetchCompletion:fetchCompletion];
    } else {
        if (fetchCompletion) {
            fetchCompletion(nil,index,NO);
        }
    }
}

-(void)fetchMediaAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:fetchMediaAtIndex:previewType:progressHandler:fetchCompletion:)]) {
        [self.dataSource previewController:self fetchMediaAtIndex:index previewType:previewType progressHandler:progressHandler fetchCompletion:fetchCompletion];
    } else {
        if (fetchCompletion) {
            fetchCompletion(nil,NO);
        }
    }
}

-(void)configPosterAndFetchMediaWithCellData:(DWMediaPreviewData *)cellData cell:(DWMediaPreviewCell *)cell previewType:(DWMediaPreviewType)previewType index:(NSUInteger)index satisfiedSize:(BOOL)satisfiedSize {
    NSUInteger originIndex = index;
    cell.poster = cellData.previewImage;
    if (previewType == DWMediaPreviewTypeImage && satisfiedSize) {
        cellData.media = cellData.previewImage;
        return;
    }
    ///这里应根据进度来在cell上展示loading.而且Loading展示应该延时一小段时间，以防止loading闪烁的问题
    [self fetchMediaAtIndex:originIndex previewType:previewType progressHandler:^(CGFloat progressNum) {
        NSLog(@"progress = %f",progressNum);
    } fetchCompletion:^(id  _Nullable media, NSUInteger index) {
        [self configMedia:media forCellData:cellData asynchronous:YES completion:^{
            if (index == cell.index) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self configMediaForCell:cell withMedia:cellData.media];
                });
            }
        }];
    }];
}

-(void)configMedia:(id)media forCellData:(DWMediaPreviewData *)cellData asynchronous:(BOOL)asynchronous completion:(dispatch_block_t)completion {
    if (cellData.previewType == DWMediaPreviewTypeAnimateImage) {
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

-(void)configMediaForCell:(DWMediaPreviewCell *)cell withMedia:(id)media {
    cell.media = media;
    ///这里在给cell设置完焦点后，要处理第一个cell获取焦点的事件
    if (!self.firstCellGotFocus) {
        self.firstCellGotFocus = YES;
        [cell getFocus];
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
            
            DWMediaPreviewData * data = [self dataAtIndex:target];
            if (data.media) {
                continue;
            }
            [indexes addObject:@(target)];
        }
        if (indexes.count) {
            [self.dataSource previewController:self prefetchMediaAtIndexes:indexes fetchCompletion:^(id  _Nullable media, NSUInteger index) {
                DWMediaPreviewData * cellData = [self dataAtIndex:index];
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
    DWMediaPreviewData * cellData = [self dataAtIndex:originIndex];
    DWMediaPreviewType previewType = cellData.previewType;
    __kindof DWMediaPreviewCell * cell;
    switch (previewType) {
        case DWMediaPreviewTypeAnimateImage:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:animateImageID forIndexPath:indexPath];
        }
            break;
        case DWMediaPreviewTypeLivePhoto:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:livePhotoID forIndexPath:indexPath];
        }
            break;
        case DWMediaPreviewTypeVideo:
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
    
    cell.isHDR = cellData.isHDR;
    [cell configIndex:originIndex];
    if (previewType != DWMediaPreviewTypeNone) {
        [self configActionForCell:cell indexPath:indexPath];
        [cell configCollectionViewController:self];
    }
    if (cellData.media) {
        ///这里如果是视频的话要即使媒体已经获取完成也要先赋值封面，因为视频要等解析完首帧后才会展现
        if (previewType == DWMediaPreviewTypeVideo) {
            cell.poster = cellData.previewImage;
        }
        
        [self configMediaForCell:cell withMedia:cellData.media];
        
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

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(DWMediaPreviewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell resignFocus];
    DWMediaPreviewCell * focusCell = collectionView.visibleCells.lastObject;
    if (focusCell) {
        [focusCell getFocus];
    } else {
        ///这里由于防止不在屏幕内滚动时导致无法获取visibleCells而无法获取焦点，所以在获取不到时置为NO，强制在cellForItem中获取焦点
        self.firstCellGotFocus = NO;
    }
}

#pragma mark --- screen rotate ---
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    _previewSize = size;
}

#pragma mark --- override ---
-(instancetype)init {
    DWMediaPreviewLayout * layout = [[DWMediaPreviewLayout alloc] init];
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
        _asyncDecodeQueue = dispatch_queue_create("com.wicky.DWMediaPreviewcontroller", DISPATCH_QUEUE_CONCURRENT);
    }
    return _asyncDecodeQueue;
}

-(NSUInteger)currentIndex {
    return _index;
}

@end
