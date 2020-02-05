//
//  DWAlbumMediaHelper.m
//  DWImagePickerController
//
//  Created by Wicky on 2020/2/5.
//

#import "DWAlbumMediaHelper.h"

@interface DWAlbumMediaHelper ()

@property (nonatomic ,strong) NSCache * posterCache;

@end

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

+(void)cachePoster:(DWImageAssetModel *)image withAsset:(PHAsset *)asset {
    if (!asset) {
        return;
    }
    DWAlbumMediaHelper * helper = [self helper];
    [helper.posterCache setObject:image forKey:asset];
}

+(DWImageAssetModel *)posterCacheForAsset:(PHAsset *)asset {
    if (!asset) {
        return nil;
    }
    DWAlbumMediaHelper * helper = [self helper];
    return [helper.posterCache objectForKey:asset];
}

#pragma mark --- tool method ---
+(instancetype)helper {
    static DWAlbumMediaHelper * h = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        h = [self new];
    });
    return h;
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

#pragma mark --- setter/getter ---
-(NSCache *)posterCache {
    if (!_posterCache) {
        _posterCache = [[NSCache alloc] init];
    }
    return _posterCache;
}

@end
