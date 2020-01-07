//
//  DWAlbumGridViewController.h
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import <UIKit/UIKit.h>
#import "DWAlbumManager.h"
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumToolBar.h"

@interface DWAlbumGridViewController : UIViewController<DWMediaPreviewDataSource>

@property (nonatomic ,assign) CGFloat itemWidth;

@property (nonatomic ,assign) NSInteger maxSelectCount;

@property (nonatomic ,strong ,readonly) DWAlbumModel * album;

@property (nonatomic ,strong) __kindof DWAlbumBaseToolBar * topToolBar;

@property (nonatomic ,strong) __kindof DWAlbumBaseToolBar * bottomToolBar;

@property (nonatomic ,strong) DWAlbumSelectionManager * selectionManager;

-(instancetype)initWithItemWidth:(CGFloat)width;

-(void)registGridCell:(Class)cellClazz;

-(void)configWithPreviewVC:(DWMediaPreviewController *)previewVC;

-(void)configWithAlbum:(DWAlbumModel *)model albumManager:(DWAlbumManager *)albumManager;

-(void)previewAtIndex:(NSInteger)index;

@end
