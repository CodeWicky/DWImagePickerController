//
//  DWAlbumMediaHelper.h
//  DWImagePickerController
//
//  Created by Wicky on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumMediaHelper : NSObject

+(DWMediaPreviewType)previewTypeForAsset:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
