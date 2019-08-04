//
//  DWAlbumListViewController.h
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import <UIKit/UIKit.h>
#import "DWAlbumGridViewController.h"

@interface DWAlbumListViewController : UITableViewController

@property (nonatomic ,strong) NSArray * albums;

@property (nonatomic ,strong) DWAlbumManager * albumManager;

-(void)configWithAlbums:(NSArray <DWAlbumModel *>*)albums albumManager:(DWAlbumManager *)albumManager;

-(void)configWithGridVC:(DWAlbumGridViewController *)gridVC;

@end
