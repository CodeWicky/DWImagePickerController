//
//  DWAlbumGridCellModel.h
//  DWAlbumGridController
//
//  Created by Wicky on 2020/2/23.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumGridCellModel : NSObject

@property (nonatomic ,strong) PHAsset * asset;

@property (nonatomic ,strong) UIImage * media;

@property (nonatomic ,assign) CGSize targetSize;

@property (nonatomic ,assign) PHAssetMediaType mediaType;

@end

NS_ASSUME_NONNULL_END
