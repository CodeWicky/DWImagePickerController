//
//  DWAlbumSelectionManager.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import <Foundation/Foundation.h>
#import "DWAlbumManager.h"
NS_ASSUME_NONNULL_BEGIN

@class DWAlbumSelectionModel;
@class DWAlbumSelectionManager;
typedef void(^DWAlbumSelectionAction)(DWAlbumSelectionManager * mgr);

@interface DWAlbumSelectionManager : NSObject

@property (nonatomic ,strong) NSMutableArray <DWAlbumSelectionModel *>* selections;

@property (nonatomic ,assign ,readonly) NSInteger maxSelectCount;

@property (nonatomic ,assign) BOOL useOriginImage;

@property (nonatomic ,copy) DWAlbumSelectionAction reachMaxSelectCount;

@property (nonatomic ,copy) DWAlbumSelectionAction sendAction;

-(instancetype)initWithMaxSelectCount:(NSInteger)maxSelectCount;

-(BOOL)addSelection:(PHAsset *)asset;

-(void)addUserInfo:(id)userInfo forAsset:(PHAsset *)asset;

-(void)addUserInfo:(id)userInfo atIndex:(NSInteger)index;

-(BOOL)removeSelection:(PHAsset *)asset;

-(BOOL)removeSelectionAtIndex:(NSInteger)index;

-(NSInteger)indexOfSelection:(PHAsset *)asset;

-(DWAlbumSelectionModel *)selectionModelAtIndex:(NSInteger)index;

-(PHAsset *)selectionAtIndex:(NSInteger)index;

@end

@interface DWAlbumSelectionModel : NSObject

@property (nonatomic ,strong) PHAsset * asset;

@property (nonatomic ,strong) id userInfo;

@end

NS_ASSUME_NONNULL_END
