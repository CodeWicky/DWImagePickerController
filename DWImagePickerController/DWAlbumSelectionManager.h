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
@interface DWAlbumSelectionManager : NSObject

@property (nonatomic ,strong) NSMutableArray <DWAlbumSelectionModel *>* selections;

@property (nonatomic ,assign ,readonly) NSInteger maxSelectCount;

@property (nonatomic ,assign) BOOL useOriginImage;

-(instancetype)initWithMaxSelectCount:(NSInteger)maxSelectCount;

-(void)addSelection:(DWImageAssetModel *)asset;

-(void)removeSelection:(DWImageAssetModel *)asset;

-(void)removeSelectionAtIndex:(NSInteger)index;

-(NSInteger)indexOfSelection:(DWImageAssetModel *)asset;

@end

@interface DWAlbumSelectionModel : NSObject

@property (nonatomic ,strong) DWImageAssetModel * asset;

@end

NS_ASSUME_NONNULL_END
