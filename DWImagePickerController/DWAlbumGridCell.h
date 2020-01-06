//
//  DWAlbumGridCell.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/6.
//

#import <UIKit/UIKit.h>
#import "DWAlbumManager.h"

@interface DWAlbumGridCell : UICollectionViewCell

@property (nonatomic ,strong) DWImageAssetModel * model;

@property (nonatomic ,assign) BOOL showSelectButton;

@property (nonatomic ,assign) BOOL canSelected;

@property (nonatomic ,copy) NSString * requestLocalID;

@property (nonatomic ,copy) void(^onSelect)(DWAlbumGridCell * cell);

-(void)setSelectAtIndex:(NSInteger)index;

@end
