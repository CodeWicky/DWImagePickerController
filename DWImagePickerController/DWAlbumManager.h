//
//  DWAlbumManager.h
//  DWAlbumPickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

static const PHImageRequestID PHCachedImageRequestID = -1;

@class DWAlbumManager,DWAlbumFetchOption,DWAlbumModel,DWAssetModel,DWImageAssetModel,DWVideoAssetModel;
NS_ASSUME_NONNULL_BEGIN

typedef void(^DWAlbumFetchCameraRollCompletion)(DWAlbumManager * _Nullable mgr ,DWAlbumModel * _Nullable obj);
typedef void(^DWAlbumFetchAlbumCompletion)(DWAlbumManager * _Nullable mgr ,NSArray <DWAlbumModel *>* _Nullable obj);
typedef void(^DWAlbumFetchImageCompletion)(DWAlbumManager * _Nullable mgr ,DWImageAssetModel * _Nullable obj);
typedef void(^DWAlbumFetchVideoCompletion)(DWAlbumManager * _Nullable mgr ,DWVideoAssetModel * _Nullable obj);

@interface DWAlbumManager : NSObject

/**
 用于获取照片的Mgr对象
 */
@property (nonatomic ,strong) PHCachingImageManager * phManager;

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
-(void)fetchCameraRollWithOption:(nullable DWAlbumFetchOption *)opt completion:(nullable DWAlbumFetchCameraRollCompletion)completion;
-(void)fetchAlbumsWithOption:(nullable DWAlbumFetchOption *)opt completion:(nullable DWAlbumFetchAlbumCompletion)completion;


/**
 获取相册封面图

 @param album 相册模型
 @param targetSize 指定尺寸
 @param completion 获取完成回调
 */
-(PHImageRequestID)fetchPostForAlbum:(DWAlbumModel *)album targetSize:(CGSize)targetSize completion:(nullable DWAlbumFetchImageCompletion)completion;


/**
 通过album及对应index获取图片或者视频，若对应角标可以命中缓存则立刻回调asset模型。
 
 @param album album模型
 @param index 要获取的图片在album中角标
 @param targetSize 指定尺寸
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id
 
 注：
 获取过程completion会回调两次，第一次返回一个缩略图，第二次返回原始图片。若命中缓存，至只走一次完成回调。
 */
-(PHImageRequestID)fetchImageWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index targetSize:(CGSize)targetSize progress:(nullable PHAssetImageProgressHandler)progress completion:(nullable DWAlbumFetchImageCompletion)completion;
-(PHImageRequestID)fetchOriginImageWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progress:(nullable PHAssetImageProgressHandler)progress completion:(nullable DWAlbumFetchImageCompletion)completion;
-(PHImageRequestID)fetchVideoWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progrss:(nullable PHAssetImageProgressHandler)progress completion:(nullable DWAlbumFetchVideoCompletion)completion;


/**
 通过asset获取相册中的图片或者视频

 @param asset 相册数据
 @param targetSize 指定尺寸
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id

 注：
 completion会回调两次，第一次返回一个缩略图，第二次返回原始图片
 */
-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize progress:(nullable PHAssetImageProgressHandler)progress completion:(nullable DWAlbumFetchImageCompletion)completion;
-(PHImageRequestID)fetchOriginImageWithAsset:(PHAsset *)asset progress:(nullable PHAssetImageProgressHandler)progress completion:(nullable DWAlbumFetchImageCompletion)completion;
-(PHImageRequestID)fetchVideoWithAsset:(PHAsset *)asset progress:(nullable PHAssetImageProgressHandler)progress
                completion:(nullable DWAlbumFetchVideoCompletion)completion;


/**
 缓存获取的asset

 @param asset asset模型
 @param album 对应的album模型
 */
-(void)cachedImageWithAsset:(DWAssetModel *)asset album:(DWAlbumModel *)album;


@end


typedef NS_ENUM(NSUInteger, DWAlbumMediaType) {
    DWAlbumMediaTypeImage,
    DWAlbumMediaTypeVideo,
    DWAlbumMediaTypeAll,
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
    DWAlbumFetchAlbumTypeAllUnited = 1 << 5,
};

@interface DWAlbumFetchOption : NSObject

@property (nonatomic ,assign) DWAlbumFetchAlbumType albumType;

@property (nonatomic ,assign) DWAlbumMediaType mediaType;

@property (nonatomic ,assign) DWAlbumSortType sortType;

@end

@interface DWAlbumModel : NSObject

@property (nonatomic ,strong ,readonly) PHFetchResult * fetchResult;

@property (nonatomic ,assign ,readonly) DWAlbumFetchAlbumType albumType;

@property (nonatomic ,assign ,readonly) DWAlbumMediaType mediaType;

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
