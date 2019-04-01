//
//  DWAlbumManager.m
//  DWAlbumPickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWAlbumManager.h"

@implementation DWAlbumModel

-(instancetype)init {
    if (self = [super init]) {
        _fetchType = DWAlbumFetchTypeAll;
        _sortType = DWAlbumSortTypeCreationDateDesending;
        _albumType = DWAlbumFetchAlbumTypeAll;
    }
    return self;
}

-(void)configTypeWithFetchOption:(DWAlbumFetchOption *)opt name:(NSString *)name result:(PHFetchResult *)result isCameraRoll:(BOOL)isCameraRoll {
    if (opt) {
        _fetchType = opt.fetchType;
        _sortType = opt.sortType;
        _albumType = opt.albumType;
    }
    _name = name;
    _isCameraRoll = isCameraRoll;
    _fetchResult = result;
    _count = result.count;
}

@end

@implementation DWAssetModel

-(void)configWithAsset:(PHAsset *)asset media:(id)media info:(NSDictionary *)info{
    _asset = asset;
    _originSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    _creationDate = asset.creationDate;
    _modificationDate = asset.modificationDate;
    _media = media;
    _info = info;
}

@end

@implementation DWImageAssetModel
@dynamic media;

@end

@implementation DWVideoAssetModel
@dynamic media;

@end

@implementation DWAlbumManager

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

-(void)fetchCameraRollWithOption:(DWAlbumFetchOption *)opt completion:(DWAlbumFetchCameraRollCompletion)completion {
    PHFetchOptions * phOpt = [self phOptFromDWOpt:opt];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    for (PHAssetCollection * obj in smartAlbums) {
        if (![obj isKindOfClass:[PHAssetCollection class]]) {
            continue;
        }
        // 过滤空相册
        if (obj.estimatedAssetCount <= 0) {
            continue;
        }
        
        if ([self isCameraRollAlbum:obj]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options:phOpt];
            if (completion) {
                DWAlbumModel * albumModel = [[DWAlbumModel alloc] init];
                [albumModel configTypeWithFetchOption:opt name:obj.localizedTitle result:fetchResult isCameraRoll:YES];
                completion(self,albumModel);
            }
            break;
        }
    }
}

-(void)fetchAlbumsWithOption:(DWAlbumFetchOption *)opt completion:(DWAlbumFetchAlbumCompletion)completion {
    PHFetchOptions * phOpt = [self phOptFromDWOpt:opt];
    NSMutableArray * allAlbums = [NSMutableArray arrayWithCapacity:5];
    
    if (!opt || opt.albumType == DWAlbumFetchAlbumTypeAll) {
        PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
        [allAlbums addObject:myPhotoStreamAlbum];
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        [allAlbums addObject:smartAlbums];
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        [allAlbums addObject:topLevelUserCollections];
        PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        [allAlbums addObject:syncedAlbums];
        PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
        [allAlbums addObject:sharedAlbums];
    } else {
        if (opt.albumType & DWAlbumFetchAlbumTypeMyPhotoSteam) {
            PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
            [allAlbums addObject:myPhotoStreamAlbum];
        }
        
        if (opt.albumType & DWAlbumFetchAlbumTypeCameraRoll) {
            PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            [allAlbums addObject:smartAlbums];
        }
        
        if (opt.albumType & DWAlbumFetchAlbumTypeTopLevelUser) {
            PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
            [allAlbums addObject:topLevelUserCollections];
        }
        
        if (opt.albumType & DWAlbumFetchAlbumTypeSyncedAlbum) {
            PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
            [allAlbums addObject:syncedAlbums];
        }
        
        if (opt.albumType & DWAlbumFetchAlbumTypeAlbumCloudShared) {
            PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
            [allAlbums addObject:sharedAlbums];
        }
    }
    BOOL needTransform = (completion != nil);
    NSMutableArray * albumArr = nil;
    if (needTransform) {
        albumArr = [NSMutableArray arrayWithCapacity:0];
    }
    
    for (PHFetchResult * album in allAlbums) {
        BOOL hasCamera = NO;
        for (PHAssetCollection * obj in album) {
            if (![obj isKindOfClass:[PHAssetCollection class]]) {
                continue;
            }
            BOOL isCamera = !hasCamera && [self isCameraRollAlbum:obj];
            if (obj.estimatedAssetCount <= 0 && !isCamera) {
                continue;
            }
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options:phOpt];
            if (fetchResult.count < 1 && !isCamera) {
                continue;
            }
            
            if (obj.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) {
                continue;
            }
            if (obj.assetCollectionSubtype == 1000000201) {
                continue; //『最近删除』相册
            }
            
            if (needTransform) {
                DWAlbumModel * albumModel = [[DWAlbumModel alloc] init];
                [albumModel configTypeWithFetchOption:opt name:obj.localizedTitle result:fetchResult isCameraRoll:isCamera];
                if (isCamera) {
                    [albumArr insertObject:albumModel atIndex:0];
                    hasCamera = YES;
                } else {
                    [albumArr addObject:albumModel];
                }
            }
        }
    }
    
    if (needTransform) {
        completion(self,albumArr);
    }
}

-(PHImageRequestID)fetchPostForAlbum:(DWAlbumModel *)album targetSize:(CGSize)targetSize completion:(DWAlbumFetchImageCompletion)completion {
    if (!album || CGSizeEqualToSize(targetSize, CGSizeZero)) {
        NSAssert(NO, @"DWAlbumManager can't fetch post for album is nil or targetSize is zero.");
        completion(self,nil);
        return PHInvalidImageRequestID;
    }
    
    PHAsset * asset = (album.sortType == DWAlbumSortTypeCreationDateAscending || album.sortType == DWAlbumSortTypeModificationDateAscending) ? album.fetchResult.lastObject : album.fetchResult.firstObject;
    
    return [self fetchImageWithAsset:asset targetSize:targetSize progress:nil completion:completion];
}

-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.progressHandler = ^(double progress_num, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(progress_num,error,stop,info);
            }
        });
    };
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        if (completion) {
            DWImageAssetModel * model = [[DWImageAssetModel alloc] init];
            [model configWithAsset:asset media:result info:info];
            completion(self,model);
        }
    }];
}

-(PHImageRequestID)fetchOriginImageWithAsset:(PHAsset *)asset progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    return [self fetchImageWithAsset:asset targetSize:PHImageManagerMaximumSize progress:progress completion:completion];
}

-(PHImageRequestID)fetchVideoWithAsset:(PHAsset *)asset progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchVideoCompletion)completion {
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.progressHandler = ^(double progress_num, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(progress_num, error, stop, info);
            }
        });
    };
    return [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:option resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
        if (completion) {
            DWVideoAssetModel * model = [[DWVideoAssetModel alloc] init];
            [model configWithAsset:asset media:playerItem info:info];
            completion(self,model);
        }
    }];
}

#pragma mark --- tool method ---
-(PHFetchOptions *)phOptFromDWOpt:(DWAlbumFetchOption *)fetchOpt {
    PHFetchOptions * opt = [[PHFetchOptions alloc] init];
    if (!fetchOpt) {
        opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    } else {
        switch (fetchOpt.fetchType) {
            case DWAlbumFetchTypeImage:
            {
                opt.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
            }
                break;
            case DWAlbumFetchTypeVideo:
            {
                opt.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                                   PHAssetMediaTypeVideo];
            }
                break;
            default:
                break;
        }
        
        switch (fetchOpt.sortType) {
            case DWAlbumSortTypeCreationDateAscending:
            {
                opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
            }
                break;
            case DWAlbumSortTypeCreationDateDesending:
            {
                opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            }
                break;
            case DWAlbumSortTypeModificationDateDesending:
            {
                opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO]];
            }
                break;
            default:
                break;
        }
    }
    return opt;
}

- (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length < 2) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length == 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}

/// 修正图片转向
- (UIImage *)fixOrientation:(UIImage *)aImage {
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}



@end

@implementation DWAlbumFetchOption

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _fetchType = DWAlbumFetchTypeAll;
        _sortType = DWAlbumSortTypeCreationDateDesending;
        _albumType = DWAlbumFetchAlbumTypeAll;
    }
    return self;
}

@end
