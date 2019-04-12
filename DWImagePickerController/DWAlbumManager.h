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

UIKIT_EXTERN NSString * _Nonnull const DWAlbumMediaSourceURL;
UIKIT_EXTERN const NSInteger DWAlbumNilObjectErrorCode;
UIKIT_EXTERN const NSInteger DWAlbumInvalidTypeErrorCode;
UIKIT_EXTERN const NSInteger DWAlbumSaveErrorCode;
UIKIT_EXTERN const NSInteger DWAlbumExportErrorCode;

@class DWAlbumManager,DWAlbumFetchOption,DWAlbumModel,DWAssetModel,DWImageAssetModel,DWVideoAssetModel,DWAlbumExportVideoOption;
NS_ASSUME_NONNULL_BEGIN

typedef void(^DWAlbumFetchCameraRollCompletion)(DWAlbumManager * _Nullable mgr ,DWAlbumModel * _Nullable obj);
typedef void(^DWAlbumFetchAlbumCompletion)(DWAlbumManager * _Nullable mgr ,NSArray <DWAlbumModel *>* _Nullable obj);
typedef void(^DWAlbumFetchImageCompletion)(DWAlbumManager * _Nullable mgr ,DWImageAssetModel * _Nullable obj);
typedef void(^DWAlbumFetchVideoCompletion)(DWAlbumManager * _Nullable mgr ,DWVideoAssetModel * _Nullable obj);
typedef void(^DWAlbumSaveMediaCompletion)(DWAlbumManager * _Nullable mgr ,BOOL success ,__kindof DWAssetModel * _Nullable obj ,NSError * _Nullable error);

typedef void(^DWAlbumExportVideoCompletion)(DWAlbumManager * _Nullable mgr ,BOOL success ,DWVideoAssetModel * _Nullable obj ,NSError * _Nullable error);

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
-(void)requestAuthorization:(nullable void(^)(PHAuthorizationStatus status))completion;


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
 @param networkAccessAllowed 是否允许从远端加载网络图片
 @param progress 获取进度
 @param completion 完成回调
 @return 获取请求的id

 注：
 completion会回调两次，第一次返回一个缩略图，第二次返回原始图片
 */
-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize networkAccessAllowed:(BOOL)networkAccessAllowed progress:(nullable PHAssetImageProgressHandler)progress completion:(nullable DWAlbumFetchImageCompletion)completion;
-(PHImageRequestID)fetchOriginImageWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(nullable PHAssetImageProgressHandler)progress completion:(nullable DWAlbumFetchImageCompletion)completion;
-(PHImageRequestID)fetchVideoWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(nullable PHAssetImageProgressHandler)progress
                completion:(nullable DWAlbumFetchVideoCompletion)completion;


/**
 缓存获取的asset

 @param asset asset模型
 @param album 对应的album模型
 */
-(void)cachedImageWithAsset:(DWAssetModel *)asset album:(DWAlbumModel *)album;


/**
 移除album模型中缓存的所有asset

 @param album album模型
 */
-(void)clearCacheForAlbum:(DWAlbumModel *)album;


/**
 保存图片至相册

 @param image 图片数据
 @param albumName 相册名称
 @param loc 地理位置信息
 @param createIfNotExist 如果相册不存在，是否创建
 @param completion 完成回调
 
 注：
 若albumName为空，则保存至系统相册cameraRoll
 */
-(void)saveImage:(UIImage *)image toAlbum:(nullable NSString *)albumName location:(nullable CLLocation *)loc  createIfNotExist:(BOOL)createIfNotExist completion:(nullable DWAlbumSaveMediaCompletion)completion;
-(void)saveImageToCameraRoll:(UIImage *)image completion:(nullable DWAlbumSaveMediaCompletion)completion;


/**
 保存视频至相册

 @param videoURL 视频URL
 @param albumName 相册名称
 @param loc 地理位置信息
 @param createIfNotExist 如果相册不存在，是否创建
 @param completion 完成回调
 
 注：
 若albumName为空，则保存至系统相册cameraRoll
 */
-(void)saveVideo:(NSURL *)videoURL toAlbum:(nullable NSString *)albumName location:(nullable CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(nullable DWAlbumSaveMediaCompletion)completion;
-(void)saveVideoToCameraRoll:(NSURL *)videoURL completion:(nullable DWAlbumSaveMediaCompletion)completion;


/**
 要导出的视频asset对象

 @param asset asset对象
 @param opt 导出配置信息
 @param completion 完成回调
 */
-(void)exportVideo:(PHAsset *)asset option:(nullable DWAlbumExportVideoOption *)opt completion:(nullable DWAlbumExportVideoCompletion)completion;

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

/**
 视频导出格式配置，具体释义见 AVAssetExportPreset 释义。
 */
typedef NS_ENUM(NSUInteger, DWAlbumExportPresetType) {
    DWAlbumExportPresetTypeLowQuality,
    DWAlbumExportPresetTypeMediumQuality,
    DWAlbumExportPresetTypeHighestQuality,
    DWAlbumExportPresetTypeHEVCHighestQuality,
    DWAlbumExportPresetType640x480,
    DWAlbumExportPresetType960x540,
    DWAlbumExportPresetType1280x720,
    DWAlbumExportPresetType1920x1080,
    DWAlbumExportPresetType3840x2160,
    DWAlbumExportPresetTypeHEVC1920x1080,
    DWAlbumExportPresetTypeHEVC3840x2160,
    DWAlbumExportPresetTypeAppleM4A,
    DWAlbumExportPresetTypePassthrough,
};


/**
 相册获取配置项
 */
@interface DWAlbumFetchOption : NSObject

///获取相册类型，默认为 DWAlbumFetchAlbumTypeAll
@property (nonatomic ,assign) DWAlbumFetchAlbumType albumType;

///获取媒体类型，默认为 DWAlbumMediaTypeAll
@property (nonatomic ,assign) DWAlbumMediaType mediaType;

///排序方式，默认为 DWAlbumSortTypeCreationDateDesending
@property (nonatomic ,assign) DWAlbumSortType sortType;

///是否允许拉取远端资源，默认为YES
@property (nonatomic ,assign) BOOL networkAccessAllowed;

@end

/**
 视频导出配置项
 */
@interface DWAlbumExportVideoOption : NSObject

///导出文件名称，若为空将自动生成文件名
@property (nonatomic ,copy) NSString * exportName;

///导出路径，若为空，将导出至 NSTemporaryDirectory()
@property (nonatomic ,copy) NSString * savePath;

///导出文件夹不存在的话是否穿自动创建，默认为YES
@property (nonatomic ,assign) BOOL createIfNotExist;

///导出格式配置，默认为 DWAlbumExportPresetTypePassthrough ,即为导出原始视频
@property (nonatomic ,assign) DWAlbumExportPresetType presetType;

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

///asset对象
@property (nonatomic ,strong ,readonly) PHAsset * asset;

///媒体对象
@property (nonatomic ,strong ,readonly) id media;

///媒体尺寸
@property (nonatomic ,assign ,readonly) CGSize originSize;

///额外信息
@property (nonatomic ,strong ,readonly) id info;

///创建时间
@property (nonatomic, strong, readonly) NSDate * creationDate;

@property (nonatomic, strong, readonly) NSDate * modificationDate;

@end

@interface DWImageAssetModel : DWAssetModel

@property (nonatomic ,strong ,readonly) UIImage * media;

///是否是缩略图
@property (nonatomic ,assign ,readonly) BOOL isDegraded;

@end

@interface DWVideoAssetModel : DWAssetModel

@property (nonatomic ,strong ,readonly) AVPlayerItem * media;

@end

NS_ASSUME_NONNULL_END
