//
//  DWAlbumMediaHelper.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import "DWAlbumSelectionManager.h"
#import "DWAlbumGridCell.h"
NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumMediaHelper : NSObject

+(DWAlbumMediaOption)mediaOptionForAsset:(PHAsset *)asset;

+(void)cachePoster:(DWAlbumGridCellModel *)image withAsset:(PHAsset *)asset;

+(DWAlbumGridCellModel *)posterCacheForAsset:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
