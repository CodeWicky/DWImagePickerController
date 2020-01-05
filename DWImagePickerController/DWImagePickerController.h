//
//  DWImagePickerController.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWAlbumManager.h"
#import <DWMediaPreviewController/DWMediaPreviewController.h>
#import "DWAlbumGridViewController.h"
#import "DWAlbumListViewController.h"
#import "DWAlbumSelectionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWImagePickerController : UINavigationController

@property (nonatomic ,strong ,readonly) DWAlbumManager * albumManager;

@property (nonatomic ,strong ,readonly) DWAlbumSelectionManager * selectionManager;

@property (nonatomic ,strong ,readonly) DWAlbumGridViewController * gridVC;

@property (nonatomic ,strong ,readonly) DWAlbumListViewController * listVC;

@property (nonatomic ,strong ,readonly) DWMediaPreviewController * previewVC;

@property (nonatomic ,assign ,readonly) DWAlbumFetchOption * fetchOption;

@property (nonatomic ,assign ,readonly) NSUInteger columnCount;

@property (nonatomic ,assign ,readonly) CGFloat spacing;

@property (nonatomic ,assign ) NSInteger maxSelectCount;

-(instancetype)initWithAlbumManager:(nullable DWAlbumManager *)albumManager option:(nullable DWAlbumFetchOption *)opt columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing;

-(void)configSelectionManager:(DWAlbumSelectionManager *)selectionManager;

-(void)configGridVC:(DWAlbumGridViewController *)gridVC;

-(void)configListVC:(DWAlbumListViewController *)listVC;

-(void)configPreviewVC:(DWMediaPreviewController *)previewVC;

-(void)fetchCameraRollWithCompletion:(dispatch_block_t)completion;

+(instancetype)showImagePickerWithAlbumManager:(nullable DWAlbumManager *)albumManager option:(nullable DWAlbumFetchOption *)opt currentVC:(UIViewController *)currentVC;

@end

NS_ASSUME_NONNULL_END
