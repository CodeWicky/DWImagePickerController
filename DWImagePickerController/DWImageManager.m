//
//  DWImageManager.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImageManager.h"

@implementation DWImageManager

#pragma mark --- interface method ---
-(PHAuthorizationStatus)authorizationStatus {
    return [PHPhotoLibrary authorizationStatus];
}

-(void)requestAuthorization:(void (^)(PHAuthorizationStatus))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
}

-(void)fetchCameraRollWithOption:(DWImageFetchOption *)opt completion:(DWImageFetchAlbumCompletion)completion {
    if (!opt) {
        opt = [[DWImageFetchOption alloc] init];
    }
    PHFetchOptions * phOpt = [[PHFetchOptions alloc] init];
    switch (opt.fetchType) {
        case DWImageFetchTypeImage:
        {
            phOpt.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        }
            break;
        case DWImageFetchTypeVideo:
        {
            phOpt.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
             PHAssetMediaTypeVideo];
        }
            break;
        default:
            break;
    }
    
    switch (opt.sortType) {
        case DWImageSortTypeCreationDateAscending:
        {
            phOpt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        }
            break;
        case DWImageSortTypeCreationDateDesending:
        {
            phOpt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        }
            break;
        case DWImageSortTypeModificationDateDesending:
        {
            phOpt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO]];
        }
            break;
        default:
            break;
    }
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[PHAssetCollection class]]) {
            return;
        }
        // 过滤空相册
        if (obj.estimatedAssetCount <= 0) {
            return;
        }
        if ([self isCameraRollAlbum:obj]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options:phOpt];
            if (completion) {
                completion(fetchResult);
            }
            *stop = YES;
        }
    }];
}

-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize completion:(DWImageFetchImageCompletion)completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            if (completion) {
                completion(result,info);
            }
        }
    }];
}

#pragma mark --- tool method ---
- (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length < 2) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length == 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 ~ 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}

@end

@implementation DWImageFetchOption

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _fetchType = DWImageFetchTypeAll;
        _sortType = DWImageSortTypeCreationDateDesending;
    }
    return self;
}

@end
