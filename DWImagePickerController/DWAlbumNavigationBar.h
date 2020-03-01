//
//  DWAlbumNavigationBar.h
//  DWAlbumGridController
//
//  Created by Wicky on 2020/3/1.
//

#import <UIKit/UIKit.h>
#import <DWAlbumGridController/DWAlbumGridController.h>
NS_ASSUME_NONNULL_BEGIN

@class DWAlbumNavigationBar;
typedef void(^DWAlbumNavigationBarAction)(DWAlbumNavigationBar * toolBar);

@interface DWAlbumNavigationBar : UIView<DWAlbumGridToolBarProtocol>


@property (nonatomic ,assign) BOOL darkModeEnabled;

@property (nonatomic ,copy) DWAlbumNavigationBarAction retAction;

+(instancetype)toolBar;

-(void)setupDefaultValue;

-(void)setupUI;

-(void)refreshUI;

-(void)refreshUserInterfaceStyle API_AVAILABLE(ios(13.0));

@end

NS_ASSUME_NONNULL_END
