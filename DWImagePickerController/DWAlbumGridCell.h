//
//  DWAlbumGridCell.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/6.
//

#import <UIKit/UIKit.h>
#import "DWAlbumManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumGridCell : UICollectionViewCell

@property (nonatomic ,strong) DWImageAssetModel * model;

@property (nonatomic ,copy) NSString * requestLocalID;

-(void)setSelectAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
