//
//  DWAlbumPreviewNavigationBar.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/1/7.
//

#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumNavigationBar.h"

@interface DWAlbumPreviewNavigationBar : DWAlbumNavigationBar<DWMediaPreviewToolBarProtocol>

@property (nonatomic ,copy) DWAlbumNavigationBarAction selectionAction;

-(void)setSelectAtIndex:(NSInteger)index;

@end
