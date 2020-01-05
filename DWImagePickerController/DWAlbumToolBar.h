//
//  DWAlbumToolBar.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import <UIKit/UIKit.h>
#import "DWAlbumSelectionManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumBaseToolBar : UIView

@property (nonatomic ,strong) DWAlbumSelectionManager * selectionManager;

-(void)configWithSelectionManager:(DWAlbumSelectionManager *)seletionManager;

-(void)refreshSelection;

@end

typedef void(^ToolBarAction)(DWAlbumBaseToolBar * toolBar);

@interface DWAlbumToolBar : DWAlbumBaseToolBar

@property (nonatomic ,copy) ToolBarAction previewAction;

@property (nonatomic ,copy) ToolBarAction originImageAction;

@property (nonatomic ,copy) ToolBarAction sendAction;

+(instancetype)toolBar;

@end

NS_ASSUME_NONNULL_END
