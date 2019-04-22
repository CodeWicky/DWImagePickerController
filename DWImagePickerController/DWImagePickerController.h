//
//  DWImagePickerController.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/4/12.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWAlbumManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWImagePickerController : UINavigationController

@property (nonatomic ,strong ,readonly) DWAlbumManager * albumManager;

@property (nonatomic ,assign ,readonly) DWAlbumFetchOption * fetchOption;

@property (nonatomic ,assign ,readonly) NSUInteger columnCount;

@property (nonatomic ,assign ,readonly) CGFloat spacing;

@property (nonatomic ,assign ) NSInteger maxSelectCount;

-(instancetype)initWithAlbumManager:(nullable DWAlbumManager *)albumManager option:(nullable DWAlbumFetchOption *)opt columnCount:(NSUInteger)columnCount spacing:(CGFloat)spacing;

-(void)fetchCameraRollWithCompletion:(dispatch_block_t)completion;

+(instancetype)showImagePickerWithAlbumManager:(nullable DWAlbumManager *)albumManager option:(nullable DWAlbumFetchOption *)opt currentVC:(UIViewController *)currentVC;

@end

NS_ASSUME_NONNULL_END
