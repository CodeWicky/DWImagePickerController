//
//  DWImagePreviewController.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DWImagePreviewType) {
    DWImagePreviewTypeNone,
    DWImagePreviewTypeImage,
    DWImagePreviewTypeAnimateImage,
    DWImagePreviewTypePhotoLive,
    DWImagePreviewTypeVideo,
};

typedef void(^DWImagePreviewFetchMediaProgress)(CGFloat progressNum);

typedef void(^DWImagePreviewFetchMediaCompletion)(_Nullable id media, NSUInteger index, BOOL preview);

@class DWImagePreviewController;

@protocol DWImagePreviewDataSource <NSObject>

@required
-(NSUInteger)countOfMediaForPreviewController:(DWImagePreviewController *)previewController;

-(DWImagePreviewType)previewController:(DWImagePreviewController *)previewController previewTypeAtIndex:(NSUInteger)index;

-(void)previewController:(DWImagePreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWImagePreviewType)previewType progress:(DWImagePreviewFetchMediaProgress)progress fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion;

@optional
-(void)previewContoller:(DWImagePreviewController *)previewController hasChangedToIndex:(NSUInteger)index;

@end

@interface DWImagePreviewController : UICollectionViewController

@property (nonatomic ,weak) id<DWImagePreviewDataSource> dataSource;

@property (nonatomic ,assign ,readonly) CGSize previewSize;

-(void)previewAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
