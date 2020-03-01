//
//  DWAlbumGridNavigationBar.h
//  DWAlbumGridController
//
//  Created by Wicky on 2020/3/1.
//

#import "DWAlbumNavigationBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumGridNavigationBar : DWAlbumNavigationBar

@property (nonatomic ,copy) DWAlbumNavigationBarAction cancelAction;

-(void)configWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
