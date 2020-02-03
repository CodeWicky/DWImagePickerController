//
//  DWMediaPreviewController.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DWMediaPreviewCell;
typedef NS_ENUM(NSUInteger, DWMediaPreviewType) {
    DWMediaPreviewTypeNone,
    DWMediaPreviewTypeImage,
    DWMediaPreviewTypeAnimateImage,
    DWMediaPreviewTypeLivePhoto,
    DWMediaPreviewTypeVideo,
    DWMediaPreviewTypeCustomize,
};


typedef void(^DWMediaPreviewFetchMediaProgress)(CGFloat progressNum,NSUInteger index);
typedef void(^DWMediaPreviewFetchPosterCompletion)(_Nullable id media, NSUInteger index, BOOL satisfiedSize);
typedef void(^DWMediaPreviewFetchMediaCompletion)(_Nullable id media, NSUInteger index);

//Protocol of toolbar for previewController.
//PreviewController使用的toolBar的协议
@protocol DWMediaPreviewToolBarProtocol

/**
 Indicates whether the tool bar is showing.
 Tool bar 是否正在展示
 */
-(BOOL)isShowing;


/**
 Notify toolbar to show with animated.
 展示工具栏
 
 @param animated 是否具有动画
 */
-(void)showToolBarWithAnimated:(BOOL)animated;


/**
 Notify toolbar to hide with animated.
 隐藏工具栏
 
 @param animated 是否具有动画
 */
-(void)hideToolBarWithAnimated:(BOOL)animated;

/**
 Indicates the baseline for toolbar
 返回toolbar的基准线
 */
-(CGFloat)baseline;

@end

//DWMediaPreviewController is a controller to preiview different type of media,support to preview UIImage/Aniamte Image/Live Photo/Video.
///DWMediaPreviewController是一个用来预览媒体资源的控制器，当前支持UIImage/Animate Image/Live Photo/Video.
@class DWMediaPreviewController;

@protocol DWMediaPreviewDataSource <NSObject>

@required
//Return the total count of media to preview.
///返回预览的媒体的总数。
-(NSUInteger)countOfMediaForPreviewController:(DWMediaPreviewController *)previewController;

//Return the preview type for media at specific index.
///返回对应角标的媒体类型。
-(DWMediaPreviewType)previewController:(DWMediaPreviewController *)previewController previewTypeAtIndex:(NSUInteger)index;

//Callback for fetching media(If there's a cache of media,this method won't be called.).
///获取对应角标的媒体的回调（如果命中缓存则不回调）。
-(void)previewController:(DWMediaPreviewController *)previewController fetchMediaAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType progressHandler:(DWMediaPreviewFetchMediaProgress)progressHandler fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion;

@optional

//Return whether the media at specific index is hdr type.
///返回对应位置的媒体是否为HDR模式资源。
-(BOOL)previewController:(DWMediaPreviewController *)previewController isHDRAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

//Callback for fetching poster at specific index(It will be called before -previewController:fetchMediaAtIndex:previewType:progressHandler:fetchCompletion: to fetch an placeholder for media.If there's a cache of media,this method won't be called.).
///获取对应角标位置占位图的回调（发生在 -previewController:fetchMediaAtIndex:previewType:progressHandler:fetchCompletion: 回调之前，预先为媒体加载占位图，如果命中缓存则不回调)。
-(void)previewController:(DWMediaPreviewController *)previewController fetchPosterAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType fetchCompletion:(DWMediaPreviewFetchPosterCompletion)fetchCompletion;

//Callback indicating whether show progress indicator when fetch media at specific index.
///表明获取指定角标的媒体资源时是否展示进度。
-(BOOL)previewController:(DWMediaPreviewController *)previewController shouldShowProgressIndicatorAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

//Callback on the index of media is showing has been changed.
///当前预览的媒体角标发生改变时回调。
-(void)previewController:(DWMediaPreviewController *)previewController hasChangedToIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

//Callback on preload media around current media.
///预加载附近媒体的回调
-(void)previewController:(DWMediaPreviewController *)previewController prefetchMediaAtIndexes:(NSArray *)indexes fetchCompletion:(DWMediaPreviewFetchMediaCompletion)fetchCompletion;

//Customize cell to preview
///返回自定制预览类型的cell
-(__kindof DWMediaPreviewCell *)previewController:(DWMediaPreviewController *)previewController cellForItemAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

//Indicates whether use poster as placeholder for customize cell.
///表明自定制预览类型的cell是否优先展示封面作为占位图
-(BOOL)previewController:(DWMediaPreviewController *)previewController usePosterAsPlaceholderForCellAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

//Callback before cell will be displayed
///预览cell即将被展示的回调
-(void)previewController:(DWMediaPreviewController *)previewController willDisplayCell:(DWMediaPreviewCell *)cell forItemAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

//Callback on displaying cell.(It will only be called when then scrollView end scrolling.)
///展示cell的回调（只有当scrollView停止滚动后调用。）
-(void)previewController:(DWMediaPreviewController *)previewController beginDisplayingCell:(DWMediaPreviewCell *)cell forItemAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

//Callback after cell end displaying
///预览cell结束展示的回调
-(void)previewController:(DWMediaPreviewController *)previewController didEndDisplayingCell:(DWMediaPreviewCell *)cell forItemAtIndex:(NSUInteger)index previewType:(DWMediaPreviewType)previewType;

@end

@interface DWMediaPreviewController : UIViewController

//The datasource for previewController.
///预览数据源。
@property (nonatomic ,weak) id<DWMediaPreviewDataSource> dataSource;

//Indicates the index of media is showing.
///当前正在展示的角标。
@property (nonatomic ,assign ,readonly) NSUInteger currentIndex;

//The current preview size of previewController.
///预览尺寸。
@property (nonatomic ,assign ,readonly) CGSize previewSize;

//Top tool bar of previewController.
///当前的顶部工具栏
@property (nonatomic ,strong) UIView <DWMediaPreviewToolBarProtocol>* topToolBar;

//Bottom tool bar of previewController.
///当前的底部工具栏
@property (nonatomic ,strong) UIView <DWMediaPreviewToolBarProtocol>* bottomToolBar;

//The limit of count to cache.
///缓存个数。
@property (nonatomic ,assign) NSUInteger cacheCount;

//The count of media to preload each time.
///预加载个数。
@property (nonatomic ,assign) NSUInteger prefetchCount;

//An flag indicates whether the is in focus media mode(it will attemp to hide tool bar and turn backgroundColor into black in focus mode)
///是否正在专注媒体模式（专注模式将隐藏工具栏并将背景转为黑色）
@property (nonatomic ,assign ,readonly) BOOL isFocusOnMedia;

//An flag indicates whether to close previewController on sliding down in preview cell.
///下滑是否关闭。
@property (nonatomic ,assign) BOOL closeOnSlidingDown;

//The threshold for slide down to close.Default by 100.
///下滑关闭的阈值，默认为100。
@property (nonatomic ,assign) CGFloat closeThreshold;

/**
 Config previewController to preview media at specific index.
 配置当前应该展示的角标。

 @param index 应该展示的角标
 
 注：在展示预览控制器前调用，用来通知预览控制器从该角标开始展示。展示中调用无效。
 */
-(void)previewAtIndex:(NSUInteger)index;

/**
 To notice the previewController that the total count of media to preview has been changed.
 通知预览控制器当前数据源个数发生改变。
 */
-(void)photoCountHasChanged;

/**
 Clear preview cache.
 清除内部缓存。
 */
-(void)clearCache;

/**
 To notice the previewController that the dataSource has been changed.
 通知预览控制器当前数据源发生改变
 
 注：内部会自动调用 -clearCache 和 -photoCountHasChanged。
 */
-(void)resetOnChangeDatasource;

/**
 Regist cell class for customize type.
 为自定制的预览类型注册重用cell

 @param clazz 重用类
 @param reuseIndentifier 重用标识
 */
-(void)registerClass:(Class)clazz forCustomizePreviewCellWithReuseIdentifier:(NSString *)reuseIndentifier;


/**
 Return reuse cell for id at index.
 根据重用标识返回指定角标的cell

 @param reuseIndentifier 重用标识
 @param index 指定角标
 @return 重用cell
 */
-(__kindof DWMediaPreviewCell *)dequeueReusablePreviewCellWithReuseIdentifier:(NSString *)reuseIndentifier forIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
