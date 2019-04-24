//
//  DWAlbumManager.m
//  DWAlbumPickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWAlbumManager.h"

NSString * const DWAlbumMediaSourceURL = @"DWAlbumMediaSourceURL";
NSString * const DWAlbumErrorDomain = @"com.DWAlbumManager.error";
const NSInteger DWAlbumNilObjectErrorCode = 10001;
const NSInteger DWAlbumInvalidTypeErrorCode = 10002;
const NSInteger DWAlbumSaveErrorCode = 10003;
const NSInteger DWAlbumExportErrorCode = 10004;

@interface DWAlbumModel ()

@property (nonatomic ,strong) NSCache * albumImageCache;

@property (nonatomic ,strong) NSCache * albumVideoCache;

@property (nonatomic ,strong) NSCache * albumDataCache;

@property (nonatomic ,strong) NSCache * albumLivePhotoCache;

@property (nonatomic ,assign) BOOL networkAccessAllowed;

@end

@implementation DWAlbumModel

-(instancetype)init {
    if (self = [super init]) {
        _mediaType = DWAlbumMediaTypeAll;
        _sortType = DWAlbumSortTypeCreationDateAscending;
        _albumType = DWAlbumFetchAlbumTypeAll;
        _networkAccessAllowed = YES;
    }
    return self;
}

-(void)configTypeWithFetchOption:(DWAlbumFetchOption *)opt name:(NSString *)name result:(PHFetchResult *)result isCameraRoll:(BOOL)isCameraRoll {
    if (opt) {
        _mediaType = opt.mediaType;
        _sortType = opt.sortType;
        _albumType = opt.albumType;
        _networkAccessAllowed = opt.networkAccessAllowed;
    }
    _name = name;
    _isCameraRoll = isCameraRoll;
    [self configWithResult:result];
}

-(void)configWithResult:(PHFetchResult *)result {
    _fetchResult = result;
    _count = result.count;
    [self clearCache];
}

-(void)clearCache {
    [_albumImageCache removeAllObjects];
    [_albumDataCache removeAllObjects];
    [_albumLivePhotoCache removeAllObjects];
    [_albumVideoCache removeAllObjects];
}

#pragma mark --- setter/getter ---
-(NSCache *)albumImageCache {
    if (!_albumImageCache) {
        _albumImageCache = [[NSCache alloc] init];
    }
    return _albumImageCache;
}

-(NSCache *)albumVideoCache {
    if (!_albumVideoCache) {
        _albumVideoCache = [[NSCache alloc] init];
    }
    return _albumVideoCache;
}

-(NSCache *)albumDataCache {
    if (!_albumDataCache) {
        _albumDataCache = [[NSCache alloc] init];
    }
    return _albumDataCache;
}

-(NSCache *)albumLivePhotoCache {
    if (!_albumLivePhotoCache) {
        _albumLivePhotoCache = [[NSCache alloc] init];
    }
    return _albumLivePhotoCache;
}

@end

@implementation DWAssetModel

-(void)configWithAsset:(PHAsset *)asset media:(id)media info:(id)info{
    _asset = asset;
    _media = media;
    _info = info;
}

-(BOOL)satisfiedSize:(CGSize)targetSize {
    return YES;
}

#pragma mark --- setter/getter ---
-(PHAssetMediaType)mediaType {
    return _asset.mediaType;
}

-(NSString *)localIdentifier {
    return _asset.localIdentifier;
}

-(NSDate *)creationDate {
    return _asset.creationDate;
}

-(NSDate *)modificationDate {
    return _asset.modificationDate;
}

-(CGSize)originSize {
    return CGSizeMake(_asset.pixelWidth, _asset.pixelHeight);
}

#pragma mark --- override ---
-(NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> (Media: %@ - Info: %@)",NSStringFromClass([self class]),self,self.media,self.info];
}

@end

@implementation DWImageAssetModel
@dynamic media;

-(void)configWithAsset:(PHAsset *)asset media:(id)media info:(id)info{
    [super configWithAsset:asset media:media info:info];
    _isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
}

-(BOOL)satisfiedSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(self.media.size, self.originSize)) {
        return YES;
    }
    
    if (CGSizeEqualToSize(targetSize, PHImageManagerMaximumSize)) {
        return CGSizeEqualToSize(self.media.size, self.originSize);
    }
    
    return self.media.size.width >= targetSize.width && self.media.size.height >= targetSize.height;
}

@end

@implementation DWVideoAssetModel
@dynamic media;

@end

@implementation DWImageDataAssetModel
@dynamic media;

-(void)configWithTargetSize:(CGSize)targetSize {
    _targetSize = targetSize;
}

-(BOOL)satisfiedSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(self.targetSize, self.originSize)) {
        return YES;
    }
    
    if (CGSizeEqualToSize(targetSize, PHImageManagerMaximumSize)) {
        return CGSizeEqualToSize(self.targetSize, PHImageManagerMaximumSize);
    }
    
    return self.targetSize.width >= targetSize.width && self.targetSize.height >= targetSize.height;
}

@end

@implementation DWLivePhotoAssetModel
@dynamic media;

-(void)configWithAsset:(PHAsset *)asset media:(id)media info:(id)info{
    [super configWithAsset:asset media:media info:info];
    _isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
}

-(BOOL)satisfiedSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(self.media.size, self.originSize)) {
        return YES;
    }
    
    if (CGSizeEqualToSize(targetSize, PHImageManagerMaximumSize)) {
        return CGSizeEqualToSize(self.media.size, self.originSize);
    }
    
    return self.media.size.width >= targetSize.width && self.media.size.height >= targetSize.height;
}

@end

@interface DWAlbumExportVideoOption ()

@property (nonatomic ,copy) NSString * presetStr;

@end

@implementation DWAlbumExportVideoOption

-(instancetype)init {
    if (self = [super init]) {
        _createIfNotExist = YES;
        _presetType = DWAlbumExportPresetTypePassthrough;
    }
    return self;
}

-(NSString *)presetStr {
    switch (_presetType) {
        case DWAlbumExportPresetTypeLowQuality:
            return AVAssetExportPresetLowQuality;
        case DWAlbumExportPresetTypeMediumQuality:
            return AVAssetExportPresetMediumQuality;
        case DWAlbumExportPresetTypeHighestQuality:
            return AVAssetExportPresetHighestQuality;
        case DWAlbumExportPresetTypeHEVCHighestQuality:
            return AVAssetExportPresetHEVCHighestQuality;
        case DWAlbumExportPresetType640x480:
            return AVAssetExportPreset640x480;
        case DWAlbumExportPresetType960x540:
            return AVAssetExportPreset960x540;
        case DWAlbumExportPresetType1280x720:
            return AVAssetExportPreset1280x720;
        case DWAlbumExportPresetType1920x1080:
            return AVAssetExportPreset1920x1080;
        case DWAlbumExportPresetType3840x2160:
            return AVAssetExportPreset3840x2160;
        case DWAlbumExportPresetTypeHEVC1920x1080:
            return AVAssetExportPresetHEVC1920x1080;
        case DWAlbumExportPresetTypeHEVC3840x2160:
            return AVAssetExportPresetHEVC3840x2160;
        case DWAlbumExportPresetTypeAppleM4A:
            return AVAssetExportPresetAppleM4A;
        case DWAlbumExportPresetTypePassthrough:
            return AVAssetExportPresetPassthrough;
        default:
            return AVAssetExportPresetPassthrough;
    }
}

@end

@interface DWAlbumManager ()

@property (nonatomic ,strong) PHImageRequestOptions * defaultOpt;

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
    PHAssetCollection * smartAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:smartAlbum options:phOpt];
    if (completion) {
        DWAlbumModel * albumModel = [[DWAlbumModel alloc] init];
        [albumModel configTypeWithFetchOption:opt name:smartAlbum.localizedTitle result:fetchResult isCameraRoll:YES];
        completion(self,albumModel);
    }
}

-(void)fetchAlbumsWithOption:(DWAlbumFetchOption *)opt completion:(DWAlbumFetchAlbumCompletion)completion {
    PHFetchOptions * phOpt = [self phOptFromDWOpt:opt];
    NSMutableArray * allAlbums = [NSMutableArray arrayWithCapacity:5];
    
    DWAlbumFetchAlbumType albumType = opt.albumType;
    if (!opt) {
        albumType = DWAlbumFetchAlbumTypeAll;
    }
    if (albumType == DWAlbumFetchAlbumTypeAllUnited) {
        PHFetchResult * allAlbum = [PHAsset fetchAssetsWithOptions:phOpt];
        [allAlbums addObject:allAlbum];
    } else {
        if (albumType & DWAlbumFetchAlbumTypeMyPhotoSteam) {
            PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
            [allAlbums addObject:myPhotoStreamAlbum];
        }
        
        if (albumType & DWAlbumFetchAlbumTypeCameraRoll) {
            PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            [allAlbums addObject:smartAlbums];
        }
        
        if (albumType & DWAlbumFetchAlbumTypeTopLevelUser) {
            PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
            [allAlbums addObject:topLevelUserCollections];
        }
        
        if (albumType & DWAlbumFetchAlbumTypeSyncedAlbum) {
            PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
            [allAlbums addObject:syncedAlbums];
        }
        
        if (albumType & DWAlbumFetchAlbumTypeAlbumCloudShared) {
            PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
            [allAlbums addObject:sharedAlbums];
        }
    }
    BOOL needTransform = (completion != nil);
    NSMutableArray * albumArr = nil;
    if (needTransform) {
        albumArr = [NSMutableArray arrayWithCapacity:0];
    }
    
    if (albumType == DWAlbumFetchAlbumTypeAllUnited) {
        PHFetchResult * album = allAlbums.firstObject;
        if (album.count && needTransform) {
            DWAlbumModel * albumModel = [[DWAlbumModel alloc] init];
            [albumModel configTypeWithFetchOption:opt name:nil result:album isCameraRoll:NO];
            [albumArr addObject:albumModel];
        }
    } else {
        
        BOOL hasCamera = NO;
        for (PHFetchResult * album in allAlbums) {
            
            for (PHAssetCollection * obj in album) {
                
                if (![obj isKindOfClass:[PHAssetCollection class]]) {
                    continue;
                }
                
                if (obj.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) {
                    continue;
                }
                
                if (obj.assetCollectionSubtype == 1000000201) {
                    continue; //『最近删除』相册
                }
                
                BOOL isCamera = YES;
                if (hasCamera) {
                    isCamera = NO;
                } else {
                    isCamera = [self isCameraRollAlbum:obj];
                }

                if (obj.estimatedAssetCount <= 0 && !isCamera) {
                    continue;
                }
                
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options:phOpt];
                if (fetchResult.count < 1 && !isCamera) {
                    continue;
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
    
    return [self fetchImageWithAsset:asset targetSize:targetSize networkAccessAllowed:YES progress:nil completion:completion];
}

-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    
    if (!asset) {
        return PHInvalidImageRequestID;
    }
    
    PHImageRequestOptions * option = nil;
    PHAssetImageProgressHandler progressHandler = nil;
    if (progress) {
        progressHandler = ^(double progress_num, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(progress_num,error,stop,info);
            });
        };
        option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.progressHandler = progressHandler;
    } else {
        option = self.defaultOpt;
    }
    
    return [self.phManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            ///本地相册
            result = [self fixOrientation:result];
            BOOL downloadFinined = (![info[PHImageCancelledKey] boolValue] && !info[PHImageErrorKey]);
            if (downloadFinined && completion) {
                DWImageAssetModel * model = [[DWImageAssetModel alloc] init];
                [model configWithAsset:asset media:result info:info];
                completion(self,model);
            }
        } else if (networkAccessAllowed && [info objectForKey:PHImageResultIsInCloudKey]) {
            ///iCloud
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.progressHandler = progressHandler;
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary * remoteinfo) {
                UIImage *resultImage = [UIImage imageWithData:imageData];
                resultImage = [self fixOrientation:resultImage];
                if (completion) {
                    DWImageAssetModel * model = [[DWImageAssetModel alloc] init];
                    [model configWithAsset:asset media:resultImage info:remoteinfo];
                    completion(self,model);
                }
            }];
        } else {
            if (completion) {
                completion(self,nil);
            }
        }
    }];
}

-(PHImageRequestID)fetchImageDataWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    if (!asset) {
        return PHInvalidImageRequestID;
    }
    
    PHImageRequestOptions * option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = networkAccessAllowed;
    if (progress) {
        option.progressHandler = ^(double progress_num, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(progress_num,error,stop,info);
            });
        };
    }
    
    return [self.phManager requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (imageData) {
            DWImageDataAssetModel * model = [[DWImageDataAssetModel alloc] init];
            [model configWithAsset:asset media:imageData info:info];
            [model configWithTargetSize:targetSize];
            if (completion) {
                completion(self,model);
            }
        } else {
            if (completion) {
                completion(self,nil);
            }
        }
    }];
}

-(PHImageRequestID)fetchLivePhotoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    if (!asset) {
        return PHInvalidImageRequestID;
    }
    
    PHLivePhotoRequestOptions * option = [[PHLivePhotoRequestOptions alloc] init];
    option.networkAccessAllowed = networkAccessAllowed;
    if (progress) {
        option.progressHandler = ^(double progress_num, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(progress_num,error,stop,info);
            });
        };
    }
    
    return [self.phManager requestLivePhotoForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        if (livePhoto) {
            DWLivePhotoAssetModel * model = [[DWLivePhotoAssetModel alloc] init];
            [model configWithAsset:asset media:livePhoto info:info];
            if (completion) {
                completion(self,model);
            }
        } else {
            if (completion) {
                completion(self,nil);
            }
        }
    }];
}

-(PHImageRequestID)fetchVideoWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchVideoCompletion)completion {
    
    if (!asset) {
        return PHInvalidImageRequestID;
    }
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.networkAccessAllowed = networkAccessAllowed;
    option.progressHandler = ^(double progress_num, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(progress_num, error, stop, info);
            }
        });
    };
    return [self.phManager requestPlayerItemForVideo:asset options:option resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
        if (completion) {
            DWVideoAssetModel * model = [[DWVideoAssetModel alloc] init];
            [model configWithAsset:asset media:playerItem info:info];
            completion(self,model);
        }
    }];
}

-(PHImageRequestID)fetchImageWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index targetSize:(CGSize)targetSize shouldCache:(BOOL)shouldCache progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    
    if (index >= album.fetchResult.count) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    DWImageAssetModel * model = [album.albumImageCache objectForKey:@(index)];
    if (model && [model satisfiedSize:targetSize]) {
        if (completion) {
            completion(self,model);
        }
        return PHCachedImageRequestID;
    }
    
    PHAsset * asset = [album.fetchResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeImage && asset.mediaType != PHAssetMediaTypeVideo) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    return [self fetchImageWithAsset:asset targetSize:targetSize networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
        if (obj && shouldCache && !obj.isDegraded) {
            [album.albumImageCache setObject:obj forKey:@(index)];
        }
        if (completion) {
            completion(mgr,obj);
        }
    }];
}

-(PHImageRequestID)fetchImageDataWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index targetSize:(CGSize)targetSize shouldCache:(BOOL)shouldCache progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    if (index >= album.fetchResult.count) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    DWImageDataAssetModel * model = [album.albumDataCache objectForKey:@(index)];
    if (model && [model satisfiedSize:targetSize]) {
        if (completion) {
            completion(self,model);
        }
        return PHCachedImageRequestID;
    }
    
    PHAsset * asset = [album.fetchResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeImage && asset.mediaType != PHAssetMediaTypeVideo) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    return [self fetchImageDataWithAsset:asset targetSize:targetSize networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager * _Nullable mgr, DWImageDataAssetModel * _Nullable obj) {
        if (obj && shouldCache) {
            [album.albumDataCache setObject:obj forKey:@(index)];
        }
        if (completion) {
            completion(mgr,obj);
        }
    }];
}

-(PHImageRequestID)fetchLivePhotoWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index targetSize:(CGSize)targetSize shouldCache:(BOOL)shouldCache progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    if (index >= album.fetchResult.count) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    DWLivePhotoAssetModel * model = [album.albumLivePhotoCache objectForKey:@(index)];
    if (model) {
        if (completion) {
            completion(self,model);
        }
        return PHCachedImageRequestID;
    }
    
    PHAsset * asset = [album.fetchResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeImage) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    return [self fetchLivePhotoWithAsset:asset targetSize:targetSize networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager * _Nullable mgr, DWLivePhotoAssetModel * _Nullable obj) {
        if (obj && shouldCache) {
            [album.albumVideoCache setObject:obj forKey:@(index)];
        }
        if (completion) {
            completion(mgr,obj);
        }
    }];
}

-(PHImageRequestID)fetchVideoWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index shouldCache:(BOOL)shouldCache progrss:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchVideoCompletion)completion {
    if (index >= album.fetchResult.count) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    DWVideoAssetModel * model = [album.albumVideoCache objectForKey:@(index)];
    if (model) {
        if (completion) {
            completion(self,model);
        }
        return PHCachedImageRequestID;
    }
    
    PHAsset * asset = [album.fetchResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeVideo) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    return [self fetchVideoWithAsset:asset networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager *mgr, DWVideoAssetModel *obj) {
        if (obj && shouldCache) {
            [album.albumVideoCache setObject:obj forKey:@(index)];
        }
        if (completion) {
            completion(mgr,obj);
        }
    }];
}

-(PHImageRequestID)fetchOriginImageWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    return [self fetchImageWithAsset:asset targetSize:PHImageManagerMaximumSize networkAccessAllowed:networkAccessAllowed progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginImageDataWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    return [self fetchImageDataWithAsset:asset targetSize:PHImageManagerMaximumSize networkAccessAllowed:networkAccessAllowed progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginLivePhotoWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    return [self fetchLivePhotoWithAsset:asset targetSize:PHImageManagerMaximumSize networkAccessAllowed:networkAccessAllowed progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginImageWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    return [self fetchImageWithAlbum:album index:index targetSize:PHImageManagerMaximumSize shouldCache:YES progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginImageDataWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    return [self fetchImageDataWithAlbum:album index:index targetSize:PHImageManagerMaximumSize shouldCache:YES progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginLivePhotoWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    return [self fetchLivePhotoWithAlbum:album index:index targetSize:PHImageManagerMaximumSize shouldCache:YES progress:progress completion:completion];
}

-(void)startCachingImagesForAssets:(NSArray <PHAsset *>*)assets targetSize:(CGSize)targetSize {
    [self.phManager startCachingImagesForAssets:assets targetSize:targetSize contentMode:PHImageContentModeAspectFill options:self.defaultOpt];
}

-(void)stopCachingImagesForAssets:(NSArray<PHAsset *> *)assets targetSize:(CGSize)targetSize {
    [self.phManager stopCachingImagesForAssets:assets targetSize:targetSize contentMode:PHImageContentModeAspectFill options:self.defaultOpt];
}

-(void)stopCachingAllImages {
    [self.phManager stopCachingImagesForAllAssets];
}

-(NSIndexSet *)startCachingImagesForAlbum:(DWAlbumModel *)album indexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    if (!album || indexes.count == 0) {
        return nil;
    }
    
    NSMutableArray <PHAsset *>* filtered = [NSMutableArray arrayWithCapacity:indexes.count];
    NSMutableIndexSet * filteredSet = [NSMutableIndexSet indexSet];
    PHFetchResult * result = album.fetchResult;
    [self filterAlbum:album indexes:indexes handler:^(NSUInteger idx, BOOL *stop) {
        [filtered addObject:[result objectAtIndex:idx]];
        [filteredSet addIndex:idx];
    }];
    [self startCachingImagesForAssets:filtered targetSize:targetSize];
    return filteredSet;
}

-(void)stopCachingImagesForAlbum:(DWAlbumModel *)album indexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    if (!album || indexes.count == 0) {
        return ;
    }
    
    NSMutableArray <PHAsset *>* filtered = [NSMutableArray arrayWithCapacity:indexes.count];
    PHFetchResult * result = album.fetchResult;
    [self filterAlbum:album indexes:indexes handler:^(NSUInteger idx, BOOL *stop) {
        [filtered addObject:[result objectAtIndex:idx]];
    }];
    [self stopCachingImagesForAssets:filtered targetSize:targetSize];
}

-(void)cancelRequestByID:(PHImageRequestID)requestID {
    [self.phManager cancelImageRequest:requestID];
}

-(void)cachedImageWithAsset:(DWAssetModel *)asset album:(DWAlbumModel *)album {
    if (!album || !asset) {
        return;
    }
    NSUInteger index = [album.fetchResult indexOfObject:asset.asset];
    if (index == NSNotFound) {
        return;
    }
    [album.albumImageCache setObject:asset forKey:@(index)];
}

-(void)clearCacheForAlbum:(DWAlbumModel *)album {
    [album clearCache];
}

-(void)saveImage:(UIImage *)image toAlbum:(NSString *)albumName location:(CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveMedia:image isPhoto:YES toAlbum:albumName location:loc createIfNotExist:createIfNotExist completion:completion];
}

-(void)saveImageToCameraRoll:(UIImage *)image completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveImage:image toAlbum:nil location:nil createIfNotExist:NO completion:completion];
}

-(void)saveVideo:(NSURL *)videoURL toAlbum:(NSString *)albumName location:(CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveMedia:videoURL isPhoto:NO toAlbum:albumName location:loc createIfNotExist:createIfNotExist completion:completion];
}

-(void)saveVideoToCameraRoll:(NSURL *)videoURL completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveVideo:videoURL toAlbum:nil location:nil createIfNotExist:NO completion:completion];
}

-(void)exportVideo:(PHAsset *)asset option:(DWAlbumExportVideoOption *)opt completion:(DWAlbumExportVideoCompletion)completion {
    if (!asset) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumNilObjectErrorCode userInfo:@{@"errMsg":@"Invalid asset who is nil."}]);
        }
        return;
    }
    
    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
        [self exportVideoWithAVAsset:(AVURLAsset *)avasset asset:asset option:opt completion:completion];
    }];
}

#pragma mark --- tool method ---
-(PHFetchOptions *)phOptFromDWOpt:(DWAlbumFetchOption *)fetchOpt {
    PHFetchOptions * opt = [[PHFetchOptions alloc] init];
    if (!fetchOpt) {
        opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    } else {
        switch (fetchOpt.mediaType) {
            case DWAlbumMediaTypeImage:
            {
                opt.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
            }
                break;
            case DWAlbumMediaTypeVideo:
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

-(void)saveMedia:(id)media isPhoto:(BOOL)isPhoto toAlbum:(NSString *)albumName location:(CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(DWAlbumSaveMediaCompletion)completion {
    
    if (!media) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumNilObjectErrorCode userInfo:@{@"errMsg":@"Invalid media which is nil."}]);
        }
        return;
    }
    
    if (![media isKindOfClass:[UIImage class]] && ![media isKindOfClass:[NSURL class]]) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumInvalidTypeErrorCode userInfo:@{@"errMsg":@"Invalid media which should be UIImage or NSURL."}]);
        }
        return;
    }
    
    if ([media isKindOfClass:[UIImage class]] && !isPhoto) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumInvalidTypeErrorCode userInfo:@{@"errMsg":@"Invalid media which should be NSURL."}]);
        }
        return;
    }
    
    PHAssetCollection * album = nil;
    if (!albumName.length) {
        album = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].firstObject;
    } else {
        ///遍历所有相册
        PHFetchResult * results = [PHAssetCollection fetchAssetCollectionsWithType:(PHAssetCollectionTypeAlbum) subtype:(PHAssetCollectionSubtypeAny) options:nil];
        for (PHAssetCollection * obj in results) {
            if ([obj.localizedTitle isEqualToString:albumName]) {
                album = obj;
                break;
            }
        }
        ///如果不存在则按需创建
        if (!album) {
            if (createIfNotExist) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    [self saveMedia:media isPhoto:isPhoto toAlbum:albumName location:loc createIfNotExist:NO completion:completion];
                }];
            } else {
                if (completion) {
                    completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumSaveErrorCode userInfo:@{@"errMsg":@"Save error for target path is not exist."}]);
                }
            }
            return;
        }
    }
    __block NSString *localIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *requestToCameraRoll = nil;
        if (isPhoto) {
            if ([media isKindOfClass:[NSURL class]]) {
                requestToCameraRoll = [PHAssetCreationRequest creationRequestForAssetFromImageAtFileURL:media];
            } else if ([media isKindOfClass:[UIImage class]]) {
                requestToCameraRoll = [PHAssetChangeRequest creationRequestForAssetFromImage:media];
            }
        } else {
            if ([media isKindOfClass:[NSURL class]]) {
                requestToCameraRoll = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:media];
            }
        }
        
        localIdentifier = requestToCameraRoll.placeholderForCreatedAsset.localIdentifier;
        requestToCameraRoll.location = loc;
        requestToCameraRoll.creationDate = [NSDate date];
        
        if (albumName) {
            PHObjectPlaceholder * placeHolder = requestToCameraRoll.placeholderForCreatedAsset;
            PHAssetCollectionChangeRequest * requestToAlbum = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
            [requestToAlbum addAssets:@[placeHolder]];
        }
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
            DWAssetModel * model = nil;
            if (isPhoto) {
                model = [[DWImageAssetModel alloc] init];
            } else {
                model = [[DWVideoAssetModel alloc] init];
            }
            
            if ([media isKindOfClass:[UIImage class]]) {
                [model configWithAsset:asset media:media info:nil];
            } else {
                [model configWithAsset:asset media:nil info:@{DWAlbumMediaSourceURL:media}];
            }
            
            if (completion) {
                completion(self,YES,model, nil);
            }
        } else {
            if (completion) {
                completion(self,NO,nil, error);
            }
        }
    }];
}

-(void)exportVideoWithAVAsset:(AVURLAsset *)avasset asset:(PHAsset *)asset option:(DWAlbumExportVideoOption *)opt completion:(DWAlbumExportVideoCompletion)completion {
    NSArray * presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avasset];
    DWAlbumExportPresetType presetType = DWAlbumExportPresetTypePassthrough;
    NSString * presetString = AVAssetExportPresetPassthrough;
    BOOL createInNotExist = YES;
    if (opt) {
        presetType = opt.presetType;
        presetString = opt.presetStr;
        createInNotExist = opt.createIfNotExist;
    }
    if (opt.presetType == presetType || [presets containsObject:opt.presetStr]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avasset presetName:presetString];
        NSString * fileName = opt.exportName?: [[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970] * 1000] stringValue];
        if (avasset.URL && avasset.URL.pathExtension) {
            fileName = [fileName stringByAppendingPathExtension:avasset.URL.pathExtension];
        } else {
            fileName = [fileName stringByAppendingPathExtension:@"mp4"];
        }
        
        NSString * exportPath = opt.savePath?:NSTemporaryDirectory();
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
            if (!createInNotExist) {
                if (completion) {
                    completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export error for target path is not exist!"}]);
                }
                return;
            } else {
                [[NSFileManager defaultManager] createDirectoryAtPath:exportPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        
        exportPath = [exportPath stringByAppendingPathComponent:fileName];
        session.outputURL = [NSURL fileURLWithPath:exportPath];
        session.shouldOptimizeForNetworkUse = YES;
        
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            if (completion) {
                completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export error for media does't support exporting."}]);
            }
            return;
        } else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        
        [session exportAsynchronouslyWithCompletionHandler:^(void) {
            
            if (completion) {
                NSError * error;
                switch (session.status) {
                    case AVAssetExportSessionStatusCompleted:
                    {
                        //doNothing
                    }
                        break;
                    case AVAssetExportSessionStatusFailed:
                    {
                        error = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export Error!",@"detail":session.error}];
                    }
                        break;
                    case AVAssetExportSessionStatusCancelled:
                    {
                        error = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export Error by canceling exporting."}];
                    }
                        break;
                    default:
                    {
                        error = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export error with unknown status"}];
                    }
                        break;
                }
                
                if (error) {
                    completion(self,NO,nil,error);
                } else {
                    DWVideoAssetModel * model = [[DWVideoAssetModel alloc] init];
                    [model configWithAsset:asset media:nil info:@{DWAlbumMediaSourceURL:exportPath}];
                    completion(self,YES,model,nil);
                }
            }
        }];
    } else {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Invalid export type which is not supported!"}]);
        }
    }
}

-(void)filterAlbum:(DWAlbumModel *)album indexes:(NSIndexSet *)indexes handler:(void (^)(NSUInteger idx, BOOL *stop))handler {
    if (!handler) {
        return;
    }
    PHFetchResult * result = album.fetchResult;
    NSUInteger count = result.count;
    NSCache * albumCache = album.albumImageCache;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < count && ![albumCache objectForKey:@(idx)]) {
            handler(idx,stop);
        }
    }];
}

#pragma mark --- setter/getter ---
-(PHCachingImageManager *)phManager {
    if (!_phManager) {
        _phManager = (PHCachingImageManager *)[PHCachingImageManager defaultManager];
    }
    return _phManager;
}

-(PHImageRequestOptions *)defaultOpt {
    if (!_defaultOpt) {
        _defaultOpt = [[PHImageRequestOptions alloc] init];
        _defaultOpt.resizeMode = PHImageRequestOptionsResizeModeFast;
    }
    return _defaultOpt;
}

@end

@implementation DWAlbumFetchOption

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _mediaType = DWAlbumMediaTypeAll;
        _sortType = DWAlbumSortTypeCreationDateAscending;
        _albumType = DWAlbumFetchAlbumTypeAll;
        _networkAccessAllowed = YES;
    }
    return self;
}

@end
