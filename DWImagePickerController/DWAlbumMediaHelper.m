//
//  DWAlbumMediaHelper.m
//  DWImagePickerController
//
//  Created by Wicky on 2020/2/5.
//

#import "DWAlbumMediaHelper.h"

@implementation DWAlbumMediaHelper

#pragma mark --- interface method ---
+(DWMediaPreviewType)previewTypeForAsset:(PHAsset *)asset {
    if (asset.mediaType == PHAssetMediaTypeImage) {
        if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
            return DWMediaPreviewTypeLivePhoto;
        } else if ([animateExtensions() containsObject:[[[asset valueForKey:@"filename"] pathExtension] lowercaseString]]) {
            return DWMediaPreviewTypeAnimateImage;
        } else {
            return DWMediaPreviewTypeImage;
        }
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        return DWMediaPreviewTypeVideo;
    } else {
        return DWMediaPreviewTypeNone;
    }
}

#pragma mark --- tool func ---
NS_INLINE NSArray * animateExtensions() {
    static NSArray * exts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exts = @[@"webp",@"gif",@"apng"];
    });
    return exts;
}

@end
