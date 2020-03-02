//
//  DWAlbumModel+DWImagePickerControllerGridModel.h
//  DWAlbumGridController
//
//  Created by Wicky on 2020/3/2.
//

#import "DWAlbumManager.h"
#import <DWAlbumGridController/DWAlbumGridController.h>
NS_ASSUME_NONNULL_BEGIN
typedef DWAlbumGridModel *_Nonnull(^DWImagePickerControllerGridModelLoader)(DWAlbumModel * album);
@interface DWAlbumModel (DWImagePickerControllerGridModel)

@property (nonatomic ,copy) DWImagePickerControllerGridModelLoader loader;

@property (nonatomic ,strong ,readonly) dispatch_queue_t fetchDataQueue;

@property (nonatomic ,strong) DWAlbumGridModel * userInfo;

-(void)autoFetchGridModelBackground;

-(void)fetchGridModelWithCompletion:(nullable void(^)(DWAlbumGridModel * gridModel))completion;

@end

NS_ASSUME_NONNULL_END
