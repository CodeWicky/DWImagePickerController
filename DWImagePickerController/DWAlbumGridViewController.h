//
//  DWAlbumGridViewController.h
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import <UIKit/UIKit.h>
#import "DWAlbumManager.h"
#import <DWMediaPreviewController/DWMediaPreviewController.h>

@interface DWAlbumGridViewController : UIViewController<DWMediaPreviewDataSource>

@property (nonatomic ,assign) CGFloat itemWidth;

-(instancetype)initWithItemWidth:(CGFloat)width;

-(void)configWithPreviewVC:(DWMediaPreviewController *)previewVC;

-(void)configWithAlbum:(DWAlbumModel *)model albumManager:(DWAlbumManager *)albumManager;

@end
