//
//  DWMediaPreviewController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWMediaPreviewController.h"
#import "DWMediaPreviewCell.h"
#import <DWKit/DWFixAdjustCollectionView.h>
#import "DWMediaPreviewImageDecoder.h"

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
    self.itemSize = self.collectionView.bounds.size;
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

@property (nonatomic ,assign) BOOL shouldShowBadge;

@property (nonatomic ,assign) BOOL isHDR;

@property (nonatomic ,assign) BOOL shouldShowProgressIndicator;

@end

@implementation DWMediaPreviewData

@end

@interface DWMediaPreviewController ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property (nonatomic ,strong) DWFixAdjustCollectionView * collectionView;

@property (nonatomic ,strong) DWMediaPreviewLayout * collectionViewLayout;

@property (nonatomic ,assign) NSInteger index;

@property (nonatomic ,assign) CGRect oriRect;

@property (nonatomic ,assign) BOOL previewSizeResized;

@property (nonatomic ,assign) BOOL indexChanged;

@property (nonatomic ,assign) BOOL sourceInteractivePopGestureEnabled;

@property (nonatomic ,assign) BOOL navigationBarShouldHidden;

@property (nonatomic ,strong) NSCache * dataCache;

@property (nonatomic ,strong) dispatch_queue_t asyncDecodeQueue;

@property (nonatomic ,assign) BOOL firstCellGotFocus;

@property (nonatomic ,assign) NSUInteger innerMediaCount;

@property (nonatomic ,copy) DWMediaPreviewCellAction tapAction;

@property (nonatomic ,copy) DWMediaPreviewCellAction doubleClickAction;

@property (nonatomic ,strong) UIColor * backgroundColorBeforeFocusMode;

@end

@implementation DWMediaPreviewController

static NSString * const normalImageID = @"DWNormalImagePreviewCell";
static NSString * const animateImageID = @"DWAnimateImagePreviewCell";
static NSString * const livePhotoID = @"DWLivePhotoPreviewCell";
static NSString * const videoImageID = @"DWVideoPreviewCell";

#pragma mark --- interface method ---
-(void)previewAtIndex:(NSUInteger)index {
    if (_isShowing) {
        ///如果展示中，调用这里说明要切换至指定角标，直接无动画切换
        index = [self getValidIndex:index];
        if (index != _index) {
            _index = index;
            [self setContentOffsetToCurrentIndex];
        }
    } else {
        ///如果不在展示中，调用这里说明要配置一会展示时的位置，所以改变角标后，记录需要改变的标志位
        if (index != _index && index < [self collectionView:self.collectionView numberOfItemsInSection:0]) {
            _index = index;
            _indexChanged = YES;
        }
    }
}

-(void)refreshCurrentPreviewLayoutWithAnimated:(BOOL)animated {
    if (_index < 0) {
        return;
    } else if (_index >= _innerMediaCount) {
        return;
    }
    
    DWMediaPreviewCell * cell = (DWMediaPreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0]];
    [cell refreshCellWithAnimated:animated];
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

-(void)registerClass:(Class)clazz forCustomizePreviewCellWithReuseIdentifier:(NSString *)reuseIndentifier {
    [self.collectionView registerClass:clazz forCellWithReuseIdentifier:reuseIndentifier];
}

-(DWMediaPreviewCell *)dequeueReusablePreviewCellWithReuseIdentifier:(NSString *)reuseIndentifier forIndex:(NSUInteger)index {
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:reuseIndentifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

-(void)setFocusMode:(BOOL)focusMode animated:(BOOL)animated {
    if (_isFocusOnMedia != focusMode) {
        if (self.topToolBar) {
            if (focusMode) {
                [self.topToolBar hideToolBarWithAnimated:animated];
            } else {
                [self.topToolBar showToolBarWithAnimated:animated];
            }
        } else {
            [self.navigationController setNavigationBarHidden:focusMode animated:animated];
        }
        
        if (self.bottomToolBar) {
            if (focusMode) {
                [self.bottomToolBar hideToolBarWithAnimated:animated];
            } else {
                [self.bottomToolBar showToolBarWithAnimated:animated];
            }
        }
        
        [self turnToDarkBackground:focusMode animated:animated];
        _isFocusOnMedia = focusMode;
    }
}

-(void)configTapOnCellAction:(DWMediaPreviewCellAction)tapAction {
    _tapAction = tapAction;
}

-(void)configDoubleClickOnCellAction:(DWMediaPreviewCellAction)doubleClickAction {
    _doubleClickAction = doubleClickAction;
}

#pragma mark --- tool method ---
-(void)showPreview {
    _isShowing = YES;
    [self configToolBarIfNeeded];
    [self setFocusMode:NO animated:NO];
    [self resizePreviewSizeIfNeeded];
    
    if (_innerMediaCount == 0) {
        return;
    }
    
    _index = [self getValidIndex:_index];
    
    if (_previewSizeResized) {
        _previewSizeResized = NO;
        _indexChanged = NO;
        [self setContentOffsetToCurrentIndex];
        [self reloadCellForCurrentIndex];
    } else if (_indexChanged) {
        _indexChanged = NO;
        [self setContentOffsetToCurrentIndex];
    } else {
        ///disappear时会释放当前cell的资源，故如果不改变位置的话，需要刷新当前cell
        [self reloadCellForCurrentIndex];
    }
}

-(void)clearPreview {
    DWMediaPreviewCell * cell = (DWMediaPreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0]];
    [cell clearCell];
    if (self.isFocusOnMedia) {
        [self turnToDarkBackground:NO animated:NO];
    }
    self.oriRect = self.collectionView.frame;
    _isShowing = NO;
}

-(void)configToolBarIfNeeded {
    self.navigationBarShouldHidden = self.navigationController.isNavigationBarHidden;
    if (self.topToolBar) {

        if (self.navigationController) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
        
        if (!self.topToolBar.superview) {
            [self.view addSubview:self.topToolBar];
        }
    }
    
    if (self.bottomToolBar && !self.bottomToolBar.superview) {
        [self.view addSubview:self.bottomToolBar];
    }
}

-(void)resizePreviewSizeIfNeeded {
    if (!CGRectEqualToRect(self.view.bounds, self.collectionView.frame)) {
        self.collectionView.frame = self.view.bounds;
    }
    if (!CGSizeEqualToSize(((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize, self.view.bounds.size)) {
        [self.collectionView.collectionViewLayout prepareLayout];
    }
    if (!CGRectEqualToRect(self.oriRect, self.collectionView.frame)) {
        _previewSize = self.view.bounds.size;
        _previewSizeResized = YES;
    }
}

-(void)setContentOffsetToCurrentIndex {
    DWMediaPreviewLayout * layout = (DWMediaPreviewLayout *)self.collectionViewLayout;
    CGFloat offset_x = _index * (layout.itemSize.width + layout.minimumLineSpacing);
    [self.collectionView setContentOffset:CGPointMake(offset_x, 0)];
}

-(void)reloadCellForCurrentIndex {
    NSIndexPath * indexPath = [NSIndexPath indexPathForItem:_index inSection:0];
    DWMediaPreviewData * cellData = [self dataAtIndex:indexPath.item];
    DWMediaPreviewCell * cell = (DWMediaPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self configCell:cell withCellData:cellData atIndexPath:indexPath];
}

-(NSInteger)getValidIndex:(NSInteger)index {
    if (index < 0) {
        index = 0;
    } else if (index >= _innerMediaCount) {
        index = _innerMediaCount - 1;
    }
    return index;
}

-(DWMediaPreviewData *)dataAtIndex:(NSUInteger)index {
    ///获取数据模型，如果不存在则创建并缓存
    DWMediaPreviewData * data = [self.dataCache objectForKey:@(index)];
    if (!data) {
        data = [[DWMediaPreviewData alloc] init];
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:previewTypeAtIndex:)]) {
            data.previewType = [self.dataSource previewController:self previewTypeAtIndex:index];
        }
        
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:shouldShowBadgeAtIndex:previewType:)]) {
            data.shouldShowBadge = [self.dataSource previewController:self shouldShowBadgeAtIndex:index previewType:data.previewType];
        } else {
            data.shouldShowBadge = YES;
        }
        
        if (data.shouldShowBadge && self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:isHDRAtIndex:previewType:)]) {
            data.isHDR = [self.dataSource previewController:self isHDRAtIndex:index previewType:data.previewType];
        }
        
        if (self.dataSource  && [self.dataSource respondsToSelector:@selector(previewController:shouldShowProgressIndicatorAtIndex:previewType:)]) {
            data.shouldShowProgressIndicator = [self.dataSource previewController:self shouldShowProgressIndicatorAtIndex:index previewType:data.previewType];
        }
        
        [self.dataCache setObject:data forKey:@(index)];
    }
    return data;
}

-(void)previewDidChangedToIndex:(UIScrollView *)scrollView {
    
    if (!self.isShowing) {
        return;
    }
    
    if (_innerMediaCount == 0) {
        _index = -1;
        return;
    }
    NSInteger page = (scrollView.contentOffset.x + _previewSize.width / 2) / _previewSize.width;
    NSUInteger targetIdx = [self getValidIndex:page];
    if (targetIdx == _index) {
        return;
    }
    _index = [self getValidIndex:page];
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:hasChangedToIndex:previewType:)]) {
        DWMediaPreviewData * data = [self dataAtIndex:_index];
        [self.dataSource previewController:self hasChangedToIndex:_index previewType:data.previewType];
    }
}

-(void)beginPreviewingAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:beginDisplayingCell:forItemAtIndex:previewType:)]) {
        DWMediaPreviewCell * cell = (DWMediaPreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        [self.dataSource previewController:self beginDisplayingCell:cell forItemAtIndex:index previewType:cell.previewType];
    }
}

-(DWMediaPreviewCell *)cellForCollectionView:(UICollectionView *)collectionView cellData:(DWMediaPreviewData *)cellData atIndexPath:(NSIndexPath *)indexPath {
    NSInteger originIndex = indexPath.item;
    DWMediaPreviewType previewType = cellData.previewType;
    DWMediaPreviewCell * cell = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:cellForItemAtIndex:previewType:)]) {
        cell = [self.dataSource previewController:self cellForItemAtIndex:originIndex previewType:previewType];
    }
    
    if (!cell) {
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
            case DWMediaPreviewTypeCustomize:
            {
                NSAssert(NO, @"You has use a DWMediaPreviewTypeCustomize media so that you must implement the protocol method: -previewController:cellForItemAtIndex:");
            }
                break;
            default:
            {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:normalImageID forIndexPath:indexPath];
            }
                break;
        }
    }
    return cell;
}

-(void)configCell:(DWMediaPreviewCell *)cell withCellData:(DWMediaPreviewData *)cellData atIndexPath:(NSIndexPath *)indexPath {
    NSInteger originIndex = indexPath.item;
    DWMediaPreviewType previewType = cellData.previewType;
    cell.shouldShowBadge = cellData.shouldShowBadge;
    cell.isHDR = cellData.isHDR;
    [cell configIndex:originIndex];
    if (previewType != DWMediaPreviewTypeNone) {
        [self configActionForCell:cell indexPath:indexPath];
        [cell configPreviewController:self];
    }
    if (cellData.media) {
        BOOL needConfigMedia = YES;
        ///这里如果是视频的话要即使媒体已经获取完成也要先赋值封面，因为视频要等解析完首帧后才会展现
        
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:usePosterAsPlaceholderForCellAtIndex:previewType:)]) {
            if ([self.dataSource previewController:self usePosterAsPlaceholderForCellAtIndex:originIndex previewType:previewType]) {
                cell.poster = cellData.previewImage;
            }
        } else {
            
            switch (previewType) {
                case DWMediaPreviewTypeVideo:
                {
                    cell.poster = cellData.previewImage;
                }
                    break;
                case DWMediaPreviewTypeImage:
                {
                    ///普通图片类型，当图片尚未解码时，以poster占位
                    if ([cellData.media isKindOfClass:[UIImage class]] && ![DWMediaPreviewImageDecoder imageDecoded:cellData.media]) {
                        ///如果poster已经存在，则直接设置poster
                        if (cellData.previewImage) {
                            cell.poster = cellData.previewImage;
                        } else {
                            ///如果不存在，先获取poster，在poster完成时在设置media。所以这里要取消下面的主动设置media
                            needConfigMedia = NO;
                            [self fetchPosterAtIndex:originIndex previewType:previewType fetchCompletion:^(id  _Nullable media, NSUInteger index, BOOL satisfiedSize) {
                                cellData.previewImage = media;
                                if (index == cell.index) {
                                    cell.poster = cellData.previewImage;
                                    [self configMediaForCell:cell withMedia:cellData.media];
                                }
                            }];
                        }
                    }
                }
                    break;
                default:
                    ///Do nothing
                    break;
            }
        }
        
        if (needConfigMedia) {
            [self configMediaForCell:cell withMedia:cellData.media];
        }
        
    } else if (cellData.previewImage) {
        [self configPosterAndFetchMediaWithCellData:cellData cell:cell previewType:previewType index:originIndex satisfiedSize:NO showProgressIndicator:cellData.shouldShowProgressIndicator];
    } else {
        [self fetchPosterAtIndex:originIndex previewType:previewType fetchCompletion:^(id  _Nullable media, NSUInteger index, BOOL satisfiedSize) {
            cellData.previewImage = media;
            if (index == cell.index) {
                [self configPosterAndFetchMediaWithCellData:cellData cell:cell previewType:previewType index:originIndex satisfiedSize:satisfiedSize showProgressIndicator:cellData.shouldShowProgressIndicator];
            }
        }];
    }
}

-(void)configActionForCell:(DWMediaPreviewCell *)cell indexPath:(NSIndexPath *)indexPath {
    __weak typeof(self)weakSelf = self;
    
    cell.tapAction = ^(DWMediaPreviewCell * _Nonnull cell, CGPoint touchLocationOnMedia) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf.tapAction) {
            strongSelf.tapAction(strongSelf, cell, indexPath.item, touchLocationOnMedia);
        }
    };
    
    cell.doubleClickAction = ^(DWMediaPreviewCell * _Nonnull cell, CGPoint touchLocationOnMedia) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf.doubleClickAction) {
            strongSelf.doubleClickAction(strongSelf, cell, indexPath.item, touchLocationOnMedia);
        }
    };
    
    cell.enterFocus = ^(DWMediaPreviewCell * _Nonnull cell ,BOOL hide) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setFocusMode:hide animated:YES];
    };
    
    cell.onSlideCloseAction = ^(DWMediaPreviewCell * _Nonnull cell) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf setFocusMode:NO animated:NO];
    };
}

-(void)turnToDarkBackground:(BOOL)dark animated:(BOOL)animated {
    if (dark) {
        self.backgroundColorBeforeFocusMode = self.view.backgroundColor;
    }
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            [self turnToDarkBackground:dark];
        }];
    } else {
        [self turnToDarkBackground:dark];
    }
    if (!dark) {
        self.backgroundColorBeforeFocusMode = nil;
    }
}

-(void)turnToDarkBackground:(BOOL)dark {
    if (dark) {
        self.view.backgroundColor = [UIColor blackColor];
    } else {
        self.view.backgroundColor = self.backgroundColorBeforeFocusMode;
    }
}

-(void)fetchPosterAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType fetchCompletion:(DWMediaPreviewFetchPosterCompletion)fetchCompletion {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:fetchPosterAtIndex:previewType:fetchCompletion:)]) {
        [self.dataSource previewController:self fetchPosterAtIndex:index previewType:previewType fetchCompletion:fetchCompletion];
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

-(void)configPosterAndFetchMediaWithCellData:(DWMediaPreviewData *)cellData cell:(DWMediaPreviewCell *)cell previewType:(DWMediaPreviewType)previewType index:(NSUInteger)index satisfiedSize:(BOOL)satisfiedSize showProgressIndicator:(BOOL)showProgressIndicator {
    cell.poster = cellData.previewImage;
    if (previewType == DWMediaPreviewTypeImage && satisfiedSize) {
        cellData.media = cellData.previewImage;
        return;
    }
    ///这里应根据进度来在cell上展示loading.而且Loading展示应该延时一小段时间，以防止loading闪烁的问题（此处需要一个cancelFlag）
    if (showProgressIndicator) {
        [cell.loadingIndicator showLoading];
        [self fetchMediaAtIndex:index previewType:previewType progressHandler:^(CGFloat progressNum, NSUInteger index) {
            if (index == cell.index) {
                [cell.loadingIndicator updateProgress:progressNum];
            }
        } fetchCompletion:^(id  _Nullable media, NSUInteger index) {
            [self configMedia:media forCellData:cellData asynchronous:YES completion:^{
                if (index == cell.index) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [cell.loadingIndicator hideLoading];
                        [self configMediaForCell:cell withMedia:cellData.media];
                    });
                }
            }];
        }];
    } else {
        [self fetchMediaAtIndex:index previewType:previewType progressHandler:nil fetchCompletion:^(id  _Nullable media, NSUInteger index) {
            [self configMedia:media forCellData:cellData asynchronous:YES completion:^{
                if (index == cell.index) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self configMediaForCell:cell withMedia:cellData.media];
                    });
                }
            }];
        }];
    }
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
        NSInteger prefetchCount = _prefetchCount;
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
    ///本次添加了toolBar后要将toolbar添加在self.view中，所以底部视图不能是collectionView，否则toolbar跟随滚动。故将collectionView缩放模式改为跟self.view等大，保证旋屏自动改变布局
    [self.view addSubview:self.collectionView];
    if (@available(iOS 11.0,*)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
    }
    self.view.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[DWNormalImagePreviewCell class] forCellWithReuseIdentifier:normalImageID];
    [self.collectionView registerClass:[DWAnimateImagePreviewCell class] forCellWithReuseIdentifier:animateImageID];
    
    
    if (@available(iOS 9.1,macOS 10.15,tvOS 10, *)) {
        [self.collectionView registerClass:[DWLivePhotoPreviewCell class] forCellWithReuseIdentifier:livePhotoID];
    }
    
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
   
    [self.navigationController setNavigationBarHidden:self.navigationBarShouldHidden animated:animated];
    
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self clearPreview];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(countOfMediaForPreviewController:)]) {
        _innerMediaCount = [self.dataSource countOfMediaForPreviewController:self];
    } else {
        _innerMediaCount = 0;
    }
    return _innerMediaCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ///取出cell相关数据
    DWMediaPreviewData * cellData = [self dataAtIndex:indexPath.item];
    ///取出对应cell
    DWMediaPreviewCell * cell = [self cellForCollectionView:collectionView cellData:cellData atIndexPath:indexPath];
    ///配置cell动作、资源等
    [self configCell:cell withCellData:cellData atIndexPath:indexPath];
    ///预加载周围4个资源
    [self prefetchMediaForCollection:collectionView indexPath:indexPath];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(DWMediaPreviewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:willDisplayCell:forItemAtIndex:previewType:)]) {
        NSUInteger index = indexPath.item;
        DWMediaPreviewData * cellData = [self dataAtIndex:index];
        [self.dataSource previewController:self willDisplayCell:cell forItemAtIndex:index previewType:cellData.previewType];
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
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:didEndDisplayingCell:forItemAtIndex:previewType:)]) {
        NSUInteger index = indexPath.item;
        DWMediaPreviewData * cellData = [self dataAtIndex:index];
        [self.dataSource previewController:self didEndDisplayingCell:cell forItemAtIndex:index previewType:cellData.previewType];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self previewDidChangedToIndex:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self beginPreviewingAtIndex:_index];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self beginPreviewingAtIndex:_index];
    }
}

#pragma mark --- screen rotate ---
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    _previewSize = size;
    self.collectionView.dw_autoFixContentOffset = YES;
}

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _index = -1;
        _cacheCount = 10;
        _prefetchCount = 2;
        _previewSize = [UIScreen mainScreen].bounds.size;
        _closeOnSlidingDown = YES;
        _closeThreshold = 100;
    }
    return self;
}

#pragma mark --- setter/getter ---
-(DWFixAdjustCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[DWFixAdjustCollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:self.collectionViewLayout];
        self.oriRect = _collectionView.frame;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        _collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _collectionView;
}

-(DWMediaPreviewLayout *)collectionViewLayout {
    if (!_collectionViewLayout) {
        _collectionViewLayout = [[DWMediaPreviewLayout alloc] init];
        _collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionViewLayout.distanceBetweenPages = 40;
        _collectionViewLayout.minimumLineSpacing = 0;
        _collectionViewLayout.minimumInteritemSpacing = 0;
        _collectionViewLayout.itemSize = [UIScreen mainScreen].bounds.size;
    }
    return _collectionViewLayout;
}

-(NSCache *)dataCache {
    if (!_dataCache) {
        _dataCache = [[NSCache alloc] init];
        _dataCache.countLimit = _cacheCount;
    }
    return _dataCache;
}

-(dispatch_queue_t)asyncDecodeQueue {
    if (!_asyncDecodeQueue) {
        _asyncDecodeQueue = dispatch_queue_create("com.wicky.DWMediaPreviewcontroller.animateImageDecodeQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _asyncDecodeQueue;
}

-(NSUInteger)currentIndex {
    return _index;
}

-(DWMediaPreviewCellAction)tapAction {
    if (!_tapAction) {
        __weak typeof(self) weakSelf = self;
        _tapAction = ^(DWMediaPreviewController * _Nonnull previewController, __kindof DWMediaPreviewCell * _Nonnull cell, NSInteger index, CGPoint touchLocationOnMedia) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf setFocusMode:!strongSelf.isFocusOnMedia animated:YES];
            [cell configBadgeIfNeeded];
        };
    }
    return _tapAction;
}

-(DWMediaPreviewCellAction)doubleClickAction {
    if (!_doubleClickAction) {
        __weak typeof(self) weakSelf = self;
        _doubleClickAction = ^(DWMediaPreviewController * _Nonnull previewController, __kindof DWMediaPreviewCell * _Nonnull cell, NSInteger index, CGPoint touchLocationOnMedia) {
            if (cell.media) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if (!strongSelf.isFocusOnMedia) {
                    [strongSelf setFocusMode:YES animated:YES];
                }
                [cell zoomMediaView:!cell.zooming point:touchLocationOnMedia];
            }
        };
    }
    return _doubleClickAction;
}

@end
