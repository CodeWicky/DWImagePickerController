//
//  DWAlbumManager.h
//  DWAlbumPickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@class DWAlbumManager,DWAlbumFetchOption,DWAlbumModel,DWAssetModel,DWImageAssetModel,DWVideoAssetModel;
typedef void(^DWAlbumFetchCameraRollCompletion)(DWAlbumManager * mgr ,DWAlbumModel * obj);
typedef void(^DWAlbumFetchAlbumCompletion)(DWAlbumManager * mgr ,NSArray <DWAlbumModel *>* obj);
typedef void(^DWAlbumFetchImageCompletion)(DWAlbumManager * mgr ,DWImageAssetModel * obj);
typedef void(^DWAlbumFetchVideoCompletion)(DWAlbumManager * mgr ,DWVideoAssetModel * obj);

NS_ASSUME_NONNULL_BEGIN

@interface DWAlbumManager : NSObject


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
-(void)fetchCameraRollWithOption:(nullable DWAlbumFetchOption *)opt completion:(DWAlbumFetchCameraRollCompletion)completion;
-(void)fetchAlbumsWithOption:(nullable DWAlbumFetchOption *)opt completion:(DWAlbumFetchAlbumCompletion)completion;


/**
 获取相册封面图

 @param album 相册模型
 @param targetSize 指定尺寸
 @param completion 获取完成回调
 */
-(PHImageRequestID)fetchPostForAlbum:(DWAlbumModel *)album targetSize:(CGSize)targetSize completion:(DWAlbumFetchImageCompletion)completion;


/**
 通过asset获取相册中的原始图片

 @param asset 相册数据
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id

 注：
 completion会回调两次，第一次返回一个缩略图，第二次返回原始图片
 */
-(PHImageRequestID)fetchOriginImageWithAsset:(PHAsset *)asset progress:(nullable PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion;


/**
 通过asset获取相册中的图片指定尺寸的副本

 @param asset 相册数据
 @param targetSize 指定尺寸
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id
 */
-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize progress:(nullable PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion;


/**
 通过asset获取相册中的视频数据

 @param asset 相册数据
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id
 */
-(PHImageRequestID)fetchVideoWithAsset:(PHAsset *)asset progress:(nullable PHAssetImageProgressHandler)progress
                completion:(DWAlbumFetchVideoCompletion)completion;


@end


typedef NS_ENUM(NSUInteger, DWAlbumFetchType) {
    DWAlbumFetchTypeImage,
    DWAlbumFetchTypeVideo,
    DWAlbumFetchTypeAll,
};

typedef NS_ENUM(NSUInteger, DWAlbumSortType) {
    DWAlbumSortTypeCreationDateAscending,
    DWAlbumSortTypeCreationDateDesending,
    DWAlbumSortTypeModificationDateAscending,
    DWAlbumSortTypeModificationDateDesending,
};

typedef NS_OPTIONS(NSUInteger, DWAlbumFetchAlbumType) {
    DWAlbumFetchAlbumTypeCameraRoll = 1 << 0,
    DWAlbumFetchAlbumTypeMyPhotoSteam = 1 << 1,
    DWAlbumFetchAlbumTypeSyncedAlbum = 1 << 2,
    DWAlbumFetchAlbumTypeAlbumCloudShared = 1 << 3,
    DWAlbumFetchAlbumTypeTopLevelUser = 1 << 4,
    DWAlbumFetchAlbumTypeAll = DWAlbumFetchAlbumTypeCameraRoll | DWAlbumFetchAlbumTypeMyPhotoSteam | DWAlbumFetchAlbumTypeSyncedAlbum | DWAlbumFetchAlbumTypeAlbumCloudShared | DWAlbumFetchAlbumTypeTopLevelUser,
};

@interface DWAlbumFetchOption : NSObject

@property (nonatomic ,assign) DWAlbumFetchAlbumType albumType;

@property (nonatomic ,assign) DWAlbumFetchType fetchType;

@property (nonatomic ,assign) DWAlbumSortType sortType;

@end

@interface DWAlbumModel : NSObject

@property (nonatomic ,strong ,readonly) PHFetchResult * fetchResult;

@property (nonatomic ,assign ,readonly) DWAlbumFetchAlbumType albumType;

@property (nonatomic ,assign ,readonly) DWAlbumFetchType fetchType;

@property (nonatomic ,assign ,readonly) DWAlbumSortType sortType;

@property (nonatomic ,copy ,readonly) NSString * name;

@property (nonatomic ,assign ,readonly) BOOL isCameraRoll;

@property (nonatomic ,assign ,readonly) NSInteger count;

@end

@interface DWAssetModel : NSObject

@property (nonatomic ,strong ,readonly) PHAsset * asset;

@property (nonatomic ,strong ,readonly) id media;

@property (nonatomic ,assign ,readonly) CGSize originSize;

@property (nonatomic ,strong ,readonly) NSDictionary * info;

@property (nonatomic, strong, readonly) NSDate * creationDate;

@property (nonatomic, strong, readonly) NSDate * modificationDate;

@end

@interface DWImageAssetModel : DWAssetModel

@property (nonatomic ,strong ,readonly) UIImage * media;

@end

@interface DWVideoAssetModel : DWAssetModel

@property (nonatomic ,strong ,readonly) AVPlayerItem * media;

@end

NS_ASSUME_NONNULL_END
