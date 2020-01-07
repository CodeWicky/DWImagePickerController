//
//  DWAlbumPreviewNavigationBar.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import <UIKit/UIKit.h>
#import <DWMediaPreviewController/DWMediaPreviewController.h>

@interface DWAlbumPreviewNavigationBar : UIView<DWMediaPreviewTopToolBarProtocol>

+(instancetype)toolBar;

@end
