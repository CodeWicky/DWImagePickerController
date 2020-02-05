//
//  DWAlbumMediaHelper.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumMediaHelper : NSObject

+(DWMediaPreviewType)previewTypeForAsset:(PHAsset *)asset;

+(void)cachePoster:(DWImageAssetModel *)image withAsset:(PHAsset *)asset;

+(DWImageAssetModel *)posterCacheForAsset:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
