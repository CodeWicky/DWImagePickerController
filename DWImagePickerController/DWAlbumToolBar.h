//
//  DWAlbumToolBar.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import <UIKit/UIKit.h>
#import <DWAlbumGridController/DWAlbumGridController.h>
NS_ASSUME_NONNULL_BEGIN

@class DWAlbumToolBar;
typedef void(^ToolBarAction)(DWAlbumToolBar * toolBar);

@interface DWAlbumToolBar : UIView<DWAlbumGridToolBarProtocol>

@property (nonatomic ,assign) BOOL darkModeEnabled;

@property (nonatomic ,copy) ToolBarAction previewAction;

@property (nonatomic ,copy) ToolBarAction originImageAction;

@property (nonatomic ,copy) ToolBarAction sendAction;

+(instancetype)toolBar;

-(void)setupDefaultValue;

-(void)setupUI;

-(void)refreshUI;

-(void)refreshUserInterfaceStyle;

@end

NS_ASSUME_NONNULL_END
