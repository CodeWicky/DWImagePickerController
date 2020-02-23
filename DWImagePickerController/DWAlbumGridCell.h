//
//  DWAlbumGridCell.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/6.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface DWAlbumGridCellModel : NSObject

@property (nonatomic ,strong) PHAsset * asset;

@property (nonatomic ,strong) UIImage * media;

@property (nonatomic ,assign) CGSize targetSize;

@property (nonatomic ,assign) PHAssetMediaType mediaType;

@end

@interface DWAlbumGridCell : UICollectionViewCell

@property (nonatomic ,strong) DWAlbumGridCellModel * model;

@property (nonatomic ,assign) BOOL showSelectButton;

@property (nonatomic ,assign) BOOL canSelected;

@property (nonatomic ,assign) NSInteger index;

@property (nonatomic ,copy) void(^onSelect)(DWAlbumGridCell * cell);

-(void)setSelectAtIndex:(NSInteger)index;

@end
