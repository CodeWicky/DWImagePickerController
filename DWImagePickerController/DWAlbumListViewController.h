//
//  DWAlbumListViewController.h
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import <UIKit/UIKit.h>
#import <DWKit/DWAlbumManager.h>

@interface DWAlbumListViewController : UITableViewController

@property (nonatomic ,assign) BOOL darkModeEnabled;

@property (nonatomic ,strong) NSArray * albums;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,copy) void(^albumSelectAction)(DWAlbumModel * album,NSIndexPath * indexPath);

-(void)configWithAlbums:(NSArray <DWAlbumModel *>*)albums albumManager:(DWAlbumManager *)albumManager;

@end
