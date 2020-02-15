//
//  DWAlbumPreviewToolBar.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import <UIKit/UIKit.h>
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumToolBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumPreviewToolBar : DWAlbumToolBar<DWMediaPreviewToolBarProtocol>

-(void)configWithAlbumManager:(DWAlbumManager *)albumManager networkAccessAllowed:(BOOL)networkAccessAllowed;

@end

NS_ASSUME_NONNULL_END
