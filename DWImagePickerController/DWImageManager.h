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
@class DWImageFetchOption;
@interface DWImageManager : NSObject

-(PHAuthorizationStatus)authorizationStatus;

-(void)requestAuthorization:(void(^)(PHAuthorizationStatus status))completion;

-(void)fetchCameraRollWithOption:(nullable DWImageFetchOption *)opt completion:(DWImageFetchAlbumCompletion)completion;

-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize completion:(DWImageFetchImageCompletion)completion;

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

@interface DWImageFetchOption : NSObject

@property (nonatomic ,assign) DWImageFetchType fetchType;

@property (nonatomic ,assign) DWImageSortType sortType;

@end

NS_ASSUME_NONNULL_END
