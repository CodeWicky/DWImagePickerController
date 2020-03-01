//
//  DWAlbumPreviewToolBar.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import <DWKit/DWAlbumManager.h>
#import "DWAlbumToolBar.h"

NS_ASSUME_NONNULL_BEGIN
@class DWAlbumPreviewToolBar;
typedef void(^PreviewToolBarAction)(DWAlbumPreviewToolBar * toolBar,NSInteger index);
@interface DWAlbumPreviewToolBar : DWAlbumToolBar<DWMediaPreviewToolBarProtocol>

@property (nonatomic ,assign) BOOL previewSelectionMode;

@property (nonatomic ,strong ,nullable) NSMutableIndexSet * previewSelectionIndexes;

@property (nonatomic ,copy) PreviewToolBarAction selectAction;

-(void)configWithAlbumManager:(DWAlbumManager *)albumManager networkAccessAllowed:(BOOL)networkAccessAllowed;

-(void)focusOnIndex:(NSInteger)index;

-(void)refreshSelectionWithAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
