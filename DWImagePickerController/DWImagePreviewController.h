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
    DWImagePreviewTypeLivePhoto,
    DWImagePreviewTypeVideo,
    DWImagePreviewTypeBigImage,
};


typedef void(^DWImagePreviewFetchMediaProgress)(CGFloat progressNum);
typedef void(^DWImagePreviewFetchPosterCompletion)(_Nullable id media, NSUInteger index, BOOL satisfiedSize);
typedef void(^DWImagePreviewFetchMediaCompletion)(_Nullable id media, NSUInteger index);

@class DWImagePreviewController;

@protocol DWImagePreviewDataSource <NSObject>

@required
///返回预览的媒体的总数
-(NSUInteger)countOfMediaForPreviewController:(DWImagePreviewController *)previewController;

///返回对应角标的媒体类型
-(DWImagePreviewType)previewController:(DWImagePreviewController *)previewController previewTypeAtIndex:(NSUInteger)index;

///获取对应角标的媒体的回调（如果命中缓存则不回调）
-(void)previewController:(DWImagePreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWImagePreviewType)previewType progressHandler:(DWImagePreviewFetchMediaProgress)progressHandler fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion;

@optional

///获取对应角标位置占位图的回调（发生在 -(void)previewController:fetchMediaAtIndex:previewType:progressHandler:fetchCompletion: 回调之前，预先为媒体加载占位图，如果命中缓存则不回调)
-(void)previewController:(DWImagePreviewController *)previewController fetchPosterAtIndex:(NSUInteger)index fetchCompletion:(DWImagePreviewFetchPosterCompletion)fetchCompletion;

///当前预览的媒体角标发生改变时回调
-(void)previewController:(DWImagePreviewController *)previewController hasChangedToIndex:(NSUInteger)index;

///预加载附近媒体的回调
-(void)previewController:(DWImagePreviewController *)previewController prefetchMediaAtIndexes:(NSArray *)indexes fetchCompletion:(DWImagePreviewFetchMediaCompletion)fetchCompletion;

@end

@interface DWImagePreviewController : UICollectionViewController

///预览数据源
@property (nonatomic ,weak) id<DWImagePreviewDataSource> dataSource;

///预览尺寸
@property (nonatomic ,assign ,readonly) CGSize previewSize;

///缓存个数
@property (nonatomic ,assign) NSUInteger cacheCount;

///预加载个数
@property (nonatomic ,assign) NSUInteger prefetchCount;

///工具栏是否正在展示
@property (nonatomic ,assign ,readonly) BOOL isToolBarShowing;

///下滑是否关闭
@property (nonatomic ,assign) BOOL closeOnSlidingDown;

/**
 配置当前应该展示的角标

 @param index 应该展示的角标
 
 注：在展示预览控制器前调用，用来通知预览控制器从该角标开始展示。展示中调用无效。
 */
-(void)previewAtIndex:(NSUInteger)index;

/**
 通知预览控制器当前数据源个数发生改变。
 */
-(void)photoCountHasChanged;

/**
 清除内部缓存
 */
-(void)clearCache;

/**
 通知预览控制器当前数据源发生改变
 
 注：内部会自动调用 -clearCache 和 -photoCountHasChanged。
 */
-(void)resetOnChangeDatasource;

@end

NS_ASSUME_NONNULL_END
