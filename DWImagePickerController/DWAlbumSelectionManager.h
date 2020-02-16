//
//  DWAlbumSelectionManager.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import <Foundation/Foundation.h>
#import "DWAlbumManager.h"
#import <DWMediaPreviewController/DWMediaPreviewController.h>
NS_ASSUME_NONNULL_BEGIN

@class DWAlbumSelectionModel;
@class DWAlbumSelectionManager;
typedef void(^DWAlbumSelectionAction)(DWAlbumSelectionManager * mgr);

@interface DWAlbumSelectionManager : NSObject

@property (nonatomic ,strong) NSMutableArray <DWAlbumSelectionModel *>* selections;

@property (nonatomic ,assign ,readonly) NSInteger maxSelectCount;

@property (nonatomic ,assign ,readonly) BOOL needsRefreshSelection;

@property (nonatomic ,assign ,readonly) BOOL reachMaxSelectCount;

@property (nonatomic ,assign) BOOL useOriginImage;

@property (nonatomic ,copy) DWAlbumSelectionAction reachMaxSelectCountAction;

@property (nonatomic ,copy) DWAlbumSelectionAction sendAction;

-(instancetype)initWithMaxSelectCount:(NSInteger)maxSelectCount;

-(BOOL)addSelection:(PHAsset *)asset mediaIndex:(NSInteger)mediaIndex previewType:(DWMediaPreviewType)previewType;

-(void)addUserInfo:(id)userInfo forAsset:(PHAsset *)asset;

-(void)addUserInfo:(id)userInfo atIndex:(NSInteger)index;

-(BOOL)removeSelection:(PHAsset *)asset;

-(BOOL)removeSelectionAtIndex:(NSInteger)index;

-(NSInteger)indexOfSelection:(PHAsset *)asset;

-(DWAlbumSelectionModel *)selectionModelAtIndex:(NSInteger)index;

-(DWAlbumSelectionModel *)selectionModelForSelection:(PHAsset *)asset;

-(PHAsset *)selectionAtIndex:(NSInteger)index;

-(void)finishRefreshSelection;

@end

@interface DWAlbumSelectionModel : NSObject

@property (nonatomic ,strong) PHAsset * asset;

@property (nonatomic ,assign) NSInteger mediaIndex;

@property (nonatomic ,assign) DWMediaPreviewType previewType;

@property (nonatomic ,strong) id userInfo;

@end

NS_ASSUME_NONNULL_END
