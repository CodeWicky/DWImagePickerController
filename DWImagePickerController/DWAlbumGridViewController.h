//
//  DWAlbumGridViewController.h
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import <UIKit/UIKit.h>
#import "DWAlbumManager.h"
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumSelectionManager.h"

@protocol DWAlbumGridToolBarProtocol <NSObject>

@property (nonatomic ,assign) CGFloat toolBarHeight;

@property (nonatomic ,strong) DWAlbumSelectionManager * selectionManager;

-(void)configWithSelectionManager:(DWAlbumSelectionManager *)selectionManager;

-(void)refreshSelection;

@end

@interface DWAlbumGridViewController : UIViewController

@property (nonatomic ,strong ,readonly) UICollectionView * gridView;

@property (nonatomic ,assign) CGFloat itemWidth;

@property (nonatomic ,assign) NSInteger maxSelectCount;

@property (nonatomic ,strong ,readonly) DWAlbumModel * album;

@property (nonatomic ,strong) UIView <DWAlbumGridToolBarProtocol>* topToolBar;

@property (nonatomic ,strong) UIView <DWAlbumGridToolBarProtocol>* bottomToolBar;

@property (nonatomic ,strong) DWAlbumSelectionManager * selectionManager;

@property (nonatomic ,copy) void(^gridClickAction)(NSIndexPath * indexPath);

-(instancetype)initWithItemWidth:(CGFloat)width;

-(void)registGridCell:(Class)cellClazz;

-(void)configWithAlbum:(DWAlbumModel *)album albumManager:(DWAlbumManager *)albumManager;

-(void)notifyPreviewIndexChangeTo:(NSInteger)index;

@end
