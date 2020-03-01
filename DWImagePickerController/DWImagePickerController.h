//
//  DWImagePickerController.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DWKit/DWAlbumManager.h>
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import <DWAlbumGridController/DWAlbumGridController.h>
#import "DWAlbumListViewController.h"

NS_ASSUME_NONNULL_BEGIN


@class DWImagePickerController;
typedef void(^DWImagePickerAction)(DWImagePickerController * imagePicker);

@interface DWImagePickerConfiguration : NSObject

@property (nonatomic ,assign) DWAlbumMediaOption displayMediaOption;

@property (nonatomic ,assign) DWAlbumMediaOption selectableOption;

@property (nonatomic ,assign) NSInteger maxSelectCount;

@property (nonatomic ,assign) BOOL multiTypeSelectionEnable;

@property (nonatomic ,assign) BOOL darkModeEnabled;

@property (nonatomic ,copy) DWImagePickerAction cancelAction;

@property (nonatomic ,copy) DWImagePickerAction sendAction;

@end

@interface DWImagePickerController : UINavigationController

@property (nonatomic ,strong ,readonly) DWAlbumManager * albumManager;

@property (nonatomic ,strong ,readonly) DWAlbumSelectionManager * selectionManager;

@property (nonatomic ,strong ,readonly) DWAlbumGridController * gridVC;

@property (nonatomic ,strong ,readonly) DWAlbumListViewController * listVC;

@property (nonatomic ,strong ,readonly) DWMediaPreviewController * previewVC;

@property (nonatomic ,assign ,readonly) DWAlbumFetchOption * fetchOption;

@property (nonatomic ,strong ,readonly) DWImagePickerConfiguration * pickerConf;

@property (nonatomic ,assign ,readonly) NSUInteger columnCount;

@property (nonatomic ,assign ,readonly) CGFloat spacing;

-(instancetype)initWithAlbumManager:(nullable DWAlbumManager *)albumManager fetchOption:(nullable DWAlbumFetchOption *)fetchOption pickerConfiguration:(nullable DWImagePickerConfiguration *)pickerConfiguration columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing;

-(void)configSelectionManager:(DWAlbumSelectionManager *)selectionManager;

-(void)configGridVC:(DWAlbumGridController *)gridVC;

-(void)configListVC:(DWAlbumListViewController *)listVC;

-(void)configPreviewVC:(DWMediaPreviewController *)previewVC;

-(void)fetchCameraRollWithCompletion:(dispatch_block_t)completion;

+(instancetype)showImagePickerWithAlbumManager:(nullable DWAlbumManager *)albumManager fetchOption:(nullable DWAlbumFetchOption *)fetchOption pickerConfiguration:(nullable DWImagePickerConfiguration *)pickerConf currentVC:(UIViewController *)currentVC;

-(void)dismissImagePickerWithCompletion:(DWImagePickerAction)completion;

@end

NS_ASSUME_NONNULL_END
