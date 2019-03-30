//
//  DWImageManager.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^DWImageFetchAlbumCompletion)(PHFetchResult * obj);
typedef void(^DWImageFetchImageCompletion)(UIImage * image,NSDictionary * info);
typedef void(^DWImageFetchVideoCompletion)(AVPlayerItem * video,NSDictionary * info);
@class DWImageFetchOption;
@interface DWImageManager : NSObject


/**
 获取授权状态

 @return 返回状态
 */
-(PHAuthorizationStatus)authorizationStatus;


/**
 请求授权

 @param completion 用户授权完成回调
 */
-(void)requestAuthorization:(void(^)(PHAuthorizationStatus status))completion;


/**
 获取相册中全部照片集合

 @param opt 获取相册的配置
 @param completion 获取完成回调
 */
-(void)fetchCameraRollWithOption:(nullable DWImageFetchOption *)opt completion:(DWImageFetchAlbumCompletion)completion;
-(void)fetchAllAlbumsWithOption:(nullable DWImageFetchOption *)opt completion:(DWImageFetchAlbumCompletion)completion;


/**
 通过asset获取相册中的原始图片

 @param asset 相册数据
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id

 注：
 completion会回调两次，第一次返回一个缩略图，第二次返回原始图片
 */
-(PHImageRequestID)fetchOriginImageWithAsset:(PHAsset *)asset progress:(nullable PHAssetImageProgressHandler)progress completion:(DWImageFetchImageCompletion)completion;


/**
 通过asset获取相册中的图片指定尺寸的副本

 @param asset 相册数据
 @param targetSize 指定尺寸
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id
 */
-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize progress:(nullable PHAssetImageProgressHandler)progress completion:(DWImageFetchImageCompletion)completion;


/**
 通过asset获取相册中的视频数据

 @param asset 相册数据
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id
 */
-(PHImageRequestID)fetchVideoWithAsset:(PHAsset *)asset progress:(nullable PHAssetImageProgressHandler)progress
                completion:(DWImageFetchVideoCompletion)completion;


@end


typedef NS_ENUM(NSUInteger, DWImageFetchType) {
    DWImageFetchTypeImage,
    DWImageFetchTypeVideo,
    DWImageFetchTypeAll,
};

typedef NS_ENUM(NSUInteger, DWImageSortType) {
    DWImageSortTypeCreationDateAscending,
    DWImageSortTypeCreationDateDesending,
    DWImageSortTypeModificationDateAscending,
    DWImageSortTypeModificationDateDesending,
};

typedef NS_OPTIONS(NSUInteger, DWImageFetchAlbumType) {
    DWImageFetchAlbumTypeCameraRoll = 1 << 0,
    DWImageFetchAlbumTypeMyPhotoSteam = 1 << 1,
    DWImageFetchAlbumTypeSyncedAlbum = 1 << 2,
    DWImageFetchAlbumTypeAlbumCloudShared = 1 << 3,
    DWImageFetchAlbumTypeTopLevelUser = 1 << 4,
};

@interface DWImageFetchOption : NSObject

@property (nonatomic ,assign) DWImageFetchAlbumType albumType;

@property (nonatomic ,assign) DWImageFetchType fetchType;

@property (nonatomic ,assign) DWImageSortType sortType;

@end

NS_ASSUME_NONNULL_END
