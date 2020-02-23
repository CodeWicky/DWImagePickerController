//
//  DWAlbumPreviewToolBar.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import <UIKit/UIKit.h>
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumToolBar.h"
#import "DWAlbumManager.h"

NS_ASSUME_NONNULL_BEGIN
@class DWAlbumPreviewToolBar;
typedef void(^PreviewToolBarAction)(DWAlbumPreviewToolBar * toolBar,NSInteger index);
@interface DWAlbumPreviewToolBar : DWAlbumToolBar<DWMediaPreviewToolBarProtocol>

@property (nonatomic ,copy) PreviewToolBarAction selectAction;

-(void)configWithAlbumManager:(DWAlbumManager *)albumManager networkAccessAllowed:(BOOL)networkAccessAllowed;

-(void)focusOnIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
