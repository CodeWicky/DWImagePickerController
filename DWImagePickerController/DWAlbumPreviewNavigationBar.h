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

@interface DWAlbumPreviewNavigationBar : UIView<DWMediaPreviewToolBarProtocol>

@property (nonatomic ,copy) DWAlbumPreviewNavigationBarAction retAction;

@property (nonatomic ,copy) DWAlbumPreviewNavigationBarAction selectionAction;

+(instancetype)toolBar;

-(void)setSelectAtIndex:(NSInteger)index;

-(void)setupDefaultValue;

-(void)setupUI;

-(void)refreshUI;

@end
