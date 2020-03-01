//
//  DWAlbumGridViewController.h
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import <UIKit/UIKit.h>
#import "DWAlbumSelectionManager.h"
#import "DWAlbumGridCellModel.h"
#import "DWAlbumGridCell.h"

@protocol DWAlbumGridToolBarProtocol <NSObject>

@property (nonatomic ,assign) CGFloat toolBarHeight;

@property (nonatomic ,strong) DWAlbumSelectionManager * selectionManager;

-(void)configWithSelectionManager:(DWAlbumSelectionManager *)selectionManager;

-(void)refreshSelection;

@end

typedef void(^DWGridViewControllerFetchCompletion)(DWAlbumGridCellModel * model);
@class DWAlbumGridController;
@protocol DWAlbumGridDataSource <NSObject>

@required
-(void)gridController:(DWAlbumGridController *)gridController fetchMediaForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize thumnail:(BOOL)thumnail completion:(DWGridViewControllerFetchCompletion)completion;

@optional
-(DWAlbumGridCell *)gridViewController:(DWAlbumGridController *)gridController cellForAsset:(PHAsset *)asset mediaOption:(DWAlbumMediaOption)mediaOption atIndex:(NSInteger)index;

-(void)gridViewController:(DWAlbumGridController *)gridController didSelectAsset:(PHAsset *)asset mediaOption:(DWAlbumMediaOption)mediaOption atIndex:(NSInteger)index;

-(void)gridController:(DWAlbumGridController *)gridController startCachingMediaForIndexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize;

-(void)gridController:(DWAlbumGridController *)gridController stopCachingMediaForIndexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize;

@end

@interface DWAlbumGridModel : NSObject

@property (nonatomic ,strong) NSArray <PHAsset *>* results;

@property (nonatomic ,copy) NSString * name;

@end

@interface DWAlbumGridController : UIViewController

@property (nonatomic ,weak) id<DWAlbumGridDataSource> dataSource;

@property (nonatomic ,strong ,readonly) UICollectionView * gridView;

@property (nonatomic ,assign) CGFloat itemWidth;

@property (nonatomic ,strong ,readonly) DWAlbumGridModel * gridModel;

@property (nonatomic ,strong) UIView <DWAlbumGridToolBarProtocol>* topToolBar;

@property (nonatomic ,strong) UIView <DWAlbumGridToolBarProtocol>* bottomToolBar;

@property (nonatomic ,strong) DWAlbumSelectionManager * selectionManager;

@property (nonatomic ,assign) BOOL autoRecoveryNavigationBar;

-(instancetype)init API_UNAVAILABLE(ios);

-(instancetype)initWithItemWidth:(CGFloat)width;

-(void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;

-(__kindof DWAlbumGridCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

-(void)configWithGridModel:(DWAlbumGridModel *)gridModel;

-(void)notifyPreviewIndexChangeTo:(NSInteger)index;

@end
