//
//  DWAlbumPreviewNavigationBar.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import <UIKit/UIKit.h>
#import <DWMediaPreviewController/DWMediaPreviewController.h>

@class DWAlbumPreviewNavigationBar;
typedef void(^DWAlbumPreviewNavigationBarAction)(DWAlbumPreviewNavigationBar * toolBar);

@interface DWAlbumPreviewNavigationBar : UIView<DWMediaPreviewTopToolBarProtocol>

@property (nonatomic ,copy) DWAlbumPreviewNavigationBarAction retAction;

+(instancetype)toolBar;

@end
