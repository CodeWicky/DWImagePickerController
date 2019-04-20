//
//  DWImagePreviewController.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImagePreviewController.h"
#import "DWImagePreviewCell.h"

@interface DWImagePreviewController ()

@property (nonatomic ,assign) CGFloat cellSpacing;

@property (nonatomic ,assign) CGFloat cellWidth;

@end


@implementation DWImagePreviewController

static NSString * const normalImageID = @"DWNormalImagePreviewCell";
static NSString * const animateImageID = @"DWAnimateImagePreviewCell";
static NSString * const photoLiveID = @"DWPhotoLivePreviewCell";
static NSString * const videoImageID = @"DWVideoPreviewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor blackColor];
    [self.collectionView registerClass:[DWNormalImagePreviewCell class] forCellWithReuseIdentifier:normalImageID];
    [self.collectionView registerClass:[DWAnimateImagePreviewCell class] forCellWithReuseIdentifier:animateImageID];
    [self.collectionView registerClass:[DWPhotoLivePreviewCell class] forCellWithReuseIdentifier:photoLiveID];
    [self.collectionView registerClass:[DWVideoPreviewCell class] forCellWithReuseIdentifier:videoImageID];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(countOfMediaForPreviewController:)]) {
        return [self.dataSource countOfMediaForPreviewController:self];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    DWImagePreviewType previewType = DWImagePreviewTypeNone;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:previewTypeAtIndex:)]) {
        previewType = [self.dataSource previewController:self previewTypeAtIndex:indexPath.row];
    }
    __kindof DWImagePreviewCell * cell;
    switch (previewType) {
        case DWImagePreviewTypeAnimateImage:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:animateImageID forIndexPath:indexPath];
        }
            break;
        case DWImagePreviewTypePhotoLive:
        {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:photoLiveID forIndexPath:indexPath];
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
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewController:fetchMediaAtIndex:previewType:progress:fetchCompletion:)]) {
        [self.dataSource previewController:self fetchMediaAtIndex:indexPath.row previewType:previewType progress:^(double progress) {
            NSLog(@"%f",progress);
        } fetchCompletion:^(id  _Nonnull media, NSUInteger index ,BOOL preview) {
            
            NSLog(@"%@,%lu,%d",media,index,preview);
            
            if (index == indexPath.row) {
                if (previewType == DWImagePreviewTypeAnimateImage && media) {
                    YYImage * image = [[YYImage alloc] initWithData:media];
                    cell.media = image;
                } else {
                    cell.media = media;
                }
            }
        }];
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSInteger page = (scrollView.contentOffset.x - _cellWidth / 2) / (_cellWidth + _cellSpacing) + 1;

    if (velocity.x > 0) page++;
    if (velocity.x < 0) page--;
    page = MAX(page,0);

    CGFloat newOffset = page * (_cellWidth + _cellSpacing);
    targetContentOffset->x = newOffset;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self previewDidChangedToIndex:scrollView];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self previewDidChangedToIndex:scrollView];
    }
}

#pragma mark --- tool method ---
-(void)previewDidChangedToIndex:(UIScrollView *)scrollView {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(previewContoller:hasChangedToIndex:)]) {
        NSInteger page = (scrollView.contentOffset.x - _cellWidth / 2) / (_cellWidth + _cellSpacing) + 1;
        [self.dataSource previewContoller:self hasChangedToIndex:page];
    }
}


#pragma mark --- override ---
-(instancetype)init {
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = [UIScreen mainScreen].bounds.size;
    if ([self initWithCollectionViewLayout:layout]) {
        _cellSpacing = layout.minimumLineSpacing;
        _cellWidth = layout.itemSize.width;
        _previewSize = layout.itemSize;
        self.collectionView.decelerationRate = 0.5;
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

@end
