//
//  DWAlbumPreviewToolBar.m
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import "DWAlbumPreviewToolBar.h"
#import <DWKit/DWLabel.h>
#import <DWAlbumGridController/DWAlbumMediaHelper.h>
#import <DWAlbumGridController/DWAlbumGridCellModel.h>

@interface DWAlbumPreviewToolBarCell : UICollectionViewCell

@property (nonatomic ,strong) UIImageView * previewImageView;

@property (nonatomic ,strong) DWAlbumGridCellModel * model;

@property (nonatomic ,assign) NSInteger index;

@property (nonatomic ,strong) UIView * shadeView;

@property (nonatomic ,strong) UIView * borderView;

-(void)setNeedsFocus:(BOOL)focus;

-(void)setNeedsSelect:(BOOL)select;

@end

@implementation DWAlbumPreviewToolBarCell

#pragma mark --- interface method ---
-(void)setNeedsFocus:(BOOL)focus {
    if (focus) {
        self.borderView.layer.borderWidth = 2;
    } else {
        self.borderView.layer.borderWidth = 0;
    }
}

-(void)setNeedsSelect:(BOOL)select {
    if (select) {
        self.shadeView.hidden = YES;
    } else {
        self.shadeView.hidden = NO;
    }
}

#pragma mark --- tool method ---
-(void)setupUI {
    [self.contentView addSubview:self.previewImageView];
    [self.contentView addSubview:self.shadeView];
    [self.contentView addSubview:self.borderView];
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.tintColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
        [self setupUI];
    }
    return self;
}

-(void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.borderView.layer.borderColor = tintColor.CGColor;
}

#pragma mark --- setter/getter ---
-(UIImageView *)previewImageView {
    if (!_previewImageView) {
        _previewImageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
        _previewImageView.clipsToBounds = YES;
        _previewImageView.layer.cornerRadius = 5;
        _previewImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _previewImageView;
}

-(UIView *)shadeView {
    if (!_shadeView) {
        _shadeView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        _shadeView.userInteractionEnabled = NO;
        _shadeView.layer.cornerRadius = 5;
        _shadeView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _shadeView;
}

-(UIView *)borderView {
    if (!_borderView) {
        _borderView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        _borderView.userInteractionEnabled = NO;
        _borderView.layer.cornerRadius = 5;
        _borderView.layer.borderWidth = 0;
        _borderView.layer.borderColor = self.tintColor.CGColor;
        _borderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _borderView;
}

-(void)setModel:(DWAlbumGridCellModel *)model {
    _model = model;
    self.previewImageView.image = model.media;
}

@end

@interface DWAlbumToolBar (Private)

@property (nonatomic ,strong) UIVisualEffectView * blurView;

@property (nonatomic ,strong) DWLabel * sendButton;

@end

@interface DWAlbumPreviewToolBar ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property (nonatomic ,strong) DWLabel * previewButton;

@property (nonatomic ,assign) BOOL show;

@property (nonatomic ,assign) CGFloat itemS;

@property (nonatomic ,assign) CGFloat previewCtnHeight;

@property (nonatomic ,assign) CGSize previewSize;

@property (nonatomic ,strong) UIView * previewCtn;

@property (nonatomic ,strong) UICollectionView * previewCol;

@property (nonatomic ,assign) BOOL previewCtnShow;

@property (nonatomic ,assign) CGFloat previewCtnOffset;

@property (nonatomic ,assign) CGFloat lastPreviewCnt;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,assign) BOOL networkAccessAllowed;

@property (nonatomic ,strong) UIView * mask;

@property (nonatomic ,assign) NSInteger originFocusIndex;

@end

@implementation DWAlbumPreviewToolBar

#pragma mark --- interface method ---
-(void)configWithAlbumManager:(DWAlbumManager *)albumManager networkAccessAllowed:(BOOL)networkAccessAllowed {
    _albumManager = albumManager;
    _networkAccessAllowed = networkAccessAllowed;
}

-(void)focusOnIndex:(NSInteger)index {
    if (_originFocusIndex != index) {
        _originFocusIndex = index;
        NSInteger count = [self collectionView:self.previewCol numberOfItemsInSection:0];
        ///这里如果count为0且index为NSNotFound的话，是取消最后一个，这里就不reload的，如果reload的话就看不到col消失动画了，在消失动画中会自动reload。所以这里屏蔽
        if (index != NSNotFound || count > 0) {
            [self.previewCol reloadData];
        }
        if (index >= 0 && index < count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.previewCol scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
            });
        }
    }
}

#pragma mark --- DWMediaPreviewToolBarProtocol method ---
-(BOOL)isShowing {
    return self.show;
}

-(void)showToolBarWithAnimated:(BOOL)animated {
    self.show = YES;
    CGRect frame = self.frame;
    frame.origin.y = self.superview.bounds.size.height - frame.size.height;
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = frame;
        }];
    } else {
        self.frame = frame;
    }
}

-(void)hideToolBarWithAnimated:(BOOL)animated {
    CGRect frame = self.frame;
    frame.origin.y = self.superview.bounds.size.height + self.previewCtnOffset;
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = frame;
        } completion:^(BOOL finished) {
            self.show = NO;
        }];
    } else {
        self.frame = frame;
        self.show = NO;
    }
}

-(CGFloat)baseline {
    return self.frame.size.height + self.previewCtnOffset;
}

#pragma mark --- collectionView delegate ---
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.previewSelectionMode) {
        return self.selectionManager.selections.count;
    }
    return self.lastPreviewCnt;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DWAlbumPreviewToolBarCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    NSInteger originIndex = indexPath.item;
    cell.index = originIndex;
    cell.tintColor = self.tintColor;
    PHAsset * asset = [self.selectionManager selectionAtIndex:originIndex];
    DWAlbumGridCellModel * media = [DWAlbumMediaHelper posterCacheForAsset:asset];
    if (media) {
        cell.model = media;
    } else {
        [self.albumManager fetchImageWithAsset:asset targetSize:self.previewSize networkAccessAllowed:self.networkAccessAllowed progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
            if (cell.index == originIndex && !obj.isDegraded) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.model = [self gridCellModelFromImageAssetModel:obj];
                });
            }
        }];
    }
    [cell setNeedsFocus:(originIndex == self.originFocusIndex)];
    [self setSelectStatusIfNeededForCell:cell atIndex:originIndex];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectAction) {
        self.selectAction(self, indexPath.item);
    }
}

#pragma mark --- tool method ---
-(DWAlbumGridCellModel *)gridCellModelFromImageAssetModel:(DWImageAssetModel *)assetModel {
    DWAlbumGridCellModel * gridModel = [DWAlbumGridCellModel new];
    gridModel.asset = assetModel.asset;
    gridModel.media = assetModel.media;
    gridModel.mediaType = assetModel.mediaType;
    gridModel.targetSize = assetModel.targetSize;
    return gridModel;
}

-(void)setSelectStatusIfNeededForCell:(DWAlbumPreviewToolBarCell *)cell atIndex:(NSInteger)index {
    if (self.previewSelectionMode) {
        if ([self.previewSelectionIndexes containsIndex:index]) {
            [cell setNeedsSelect:YES];
        } else {
            [cell setNeedsSelect:NO];
        }
    } else {
        [cell setNeedsSelect:YES];
    }
}

#pragma mark --- override ---

-(void)setupDefaultValue {
    [super setupDefaultValue];
    _show = YES;
    _originFocusIndex = NSNotFound;
    self.tintColor = [UIColor colorWithRed:49.0 / 255 green:179.0 / 255 blue:244.0 / 255 alpha:1];
    self.itemS = 64;
    self.previewCtnHeight = self.itemS + 10;
    self.previewSize = CGSizeMake(self.itemS * 2, self.itemS * 2);
}

-(void)setupUI {
    [super setupUI];
    self.maskView = self.mask;
    [self addSubview:self.previewCtn];
    [self.previewCtn addSubview:self.previewCol];
}

-(void)refreshUI {
    [self refreshUIWithAnimated:NO];
}

-(void)refreshSelection {
    [self refreshUIWithAnimated:YES];
}

-(void)refreshUIWithAnimated:(BOOL)animated {
    [super refreshUI];
    if (self.previewSelectionMode) {
        if (self.previewSelectionIndexes.count) {
            self.sendButton.text = [NSString stringWithFormat:@"完成(%lu)",(unsigned long)self.previewSelectionIndexes.count];
            self.sendButton.userInteractionEnabled = YES;
            self.sendButton.backgroundColor = self.tintColor;
        } else {
            self.sendButton.text = @"完成";
            self.sendButton.userInteractionEnabled = NO;
            self.sendButton.backgroundColor = [UIColor lightGrayColor];
        }
        [self.sendButton sizeToFit];
        CGRect btnFrame = self.sendButton.frame;
        CGSize btnSize = btnFrame.size;
        btnFrame.origin.y = (self.toolBarHeight - btnSize.height) * 0.5;
        btnFrame.origin.x = self.superview.bounds.size.width - 15 - btnSize.width;
        
        if (@available(iOS 11.0,*)) {
            btnFrame.origin.x -= self.safeAreaInsets.right;
        }
        
        self.sendButton.frame = btnFrame;
    }
    
    if (!self.show) {
        CGRect frame =  self.frame;
        frame.origin.y = self.superview.bounds.size.height;
        self.frame = frame;
    }
    
    NSInteger count = self.selectionManager.selections.count;
    BOOL toShow = (count != 0);
    BOOL showStatusChange = (self.lastPreviewCnt != count) && (self.previewCtnShow != toShow);
    
    CGRect frame = self.previewCtn.frame;
    frame.size.width = self.bounds.size.width;
    if (!CGRectEqualToRect(self.previewCtn.frame, frame)) {
        self.previewCtn.frame = frame;
    }
    
    frame.size.height += self.bounds.size.height;
    if (!CGRectEqualToRect(self.blurView.frame, frame)) {
        self.blurView.frame = frame;
    }
    
    if (!toShow) {
        frame.origin.y = 0;
        frame.size.height = self.bounds.size.height;
    }
    
    if (!CGRectEqualToRect(self.mask.frame, frame)) {
        
        CGRect oriBlurRect = self.mask.frame;
        oriBlurRect.size.width = frame.size.width;
        if (CGRectGetMaxY(oriBlurRect) != self.bounds.size.height) {
            oriBlurRect.size.height = self.bounds.size.height;
            self.mask.frame = oriBlurRect;
            [self.mask layoutSubviews];
        }
        
        if (!CGRectEqualToRect(oriBlurRect, frame)) {
            if (animated) {
                [UIView animateWithDuration:0.25 animations:^{
                    self.mask.frame = frame;
                }];
            } else {
                self.mask.frame = frame;
            }
        }
    }
    
    ///当是预览选择模式时，个数永远不会变，但这时也要刷新
    if (self.previewSelectionMode) {
        self.previewCtnShow = YES;
        self.previewCtn.alpha = 1;
        [self.previewCol reloadData];
    } else {
        if (self.lastPreviewCnt != count) {
            self.lastPreviewCnt = count;
            
            if (showStatusChange) {
                self.previewCtnShow = toShow;
                if (toShow) {
                    if (animated) {
                        [UIView animateWithDuration:0.25 animations:^{
                            self.previewCtn.alpha = 1;
                        }];
                    } else {
                        self.previewCtn.alpha = 1;
                    }
                } else {
                    if (animated) {
                        [UIView animateWithDuration:0.25 animations:^{
                            self.previewCtn.alpha = 0;
                        } completion:^(BOOL finished) {
                            [self.previewCol reloadData];
                        }];
                    } else {
                        self.previewCtn.alpha = 0;
                        [self.previewCol reloadData];
                    }
                }
            }
            if (!(showStatusChange && !toShow)) {
                [self.previewCol reloadData];
            }
        }
    }
}

-(void)refreshSelectionWithAnimated:(BOOL)animated {
    [self refreshUIWithAnimated:animated];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL inside = [super pointInside:point withEvent:event];
    if (!self.previewCtnShow || inside) {
        return inside;
    }
    return CGRectContainsPoint(self.previewCtn.frame, point);
}

-(void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    if (self.selectionManager.selections.count && self.originFocusIndex != NSNotFound) {
        DWAlbumPreviewToolBarCell * focusCell = (DWAlbumPreviewToolBarCell *)[_previewCol cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.originFocusIndex inSection:0]];
        [focusCell setTintColor:tintColor];
    }
}

#pragma mark --- setter/getter ---
-(UIView *)previewCtn {
    if (!_previewCtn) {
        _previewCtn = [[UIView alloc] initWithFrame:CGRectMake(0, -self.previewCtnHeight, self.bounds.size.width, self.previewCtnHeight)];
        _previewCtn.alpha = 0;
    }
    return _previewCtn;
}

-(UICollectionView *)previewCol {
    if (!_previewCol) {
        UICollectionViewFlowLayout * layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CGSizeMake(self.itemS, self.itemS);
        layout.minimumLineSpacing = 5;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _previewCol = [[UICollectionView alloc] initWithFrame:self.previewCtn.bounds collectionViewLayout:layout];
        _previewCol.showsHorizontalScrollIndicator = NO;
        _previewCol.backgroundColor = [UIColor clearColor];
        _previewCol.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _previewCol.contentInset = UIEdgeInsetsMake(10, 15, 0, 15);
        _previewCol.delegate = self;
        _previewCol.dataSource = self;
        [_previewCol registerClass:[DWAlbumPreviewToolBarCell class] forCellWithReuseIdentifier:@"cell"];
    }
    return _previewCol;
}

-(UIView *)mask {
    if (!_mask) {
        _mask = [UIView new];
        _mask.backgroundColor = [UIColor whiteColor];
    }
    return _mask;
}

-(CGFloat)previewCtnOffset {
    return self.previewCtnShow?self.previewCtnHeight:0;
}

@end
