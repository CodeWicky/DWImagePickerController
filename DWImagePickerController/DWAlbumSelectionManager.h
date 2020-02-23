//
//  DWAlbumSelectionManager.h
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, DWAlbumMediaOption) {
    DWAlbumMediaOptionUndefine = 0,
    DWAlbumMediaOptionImage = 1 << 0,
    DWAlbumMediaOptionAnimateImage = 1 << 1,
    DWAlbumMediaOptionLivePhoto = 1 << 2,
    DWAlbumMediaOptionVideo = 1 << 3,
    
    ///聚合类型
    DWAlbumMediaOptionAll = DWAlbumMediaOptionImage | DWAlbumMediaOptionAnimateImage | DWAlbumMediaOptionLivePhoto | DWAlbumMediaOptionVideo,
    
    ///Mask
    DWAlbumMediaOptionImageMask = DWAlbumMediaOptionImage | DWAlbumMediaOptionAnimateImage | DWAlbumMediaOptionLivePhoto,
    DWAlbumMediaOptionVideoMask = DWAlbumMediaOptionLivePhoto | DWAlbumMediaOptionVideo,
};

@class DWAlbumSelectionModel;
@class DWAlbumSelectionManager;
typedef void(^DWAlbumSelectionAction)(DWAlbumSelectionManager * mgr);

@interface DWAlbumSelectionManager : NSObject

@property (nonatomic ,strong) NSMutableArray <DWAlbumSelectionModel *>* selections;

@property (nonatomic ,assign ,readonly) NSInteger maxSelectCount;

@property (nonatomic ,assign ,readonly) BOOL needsRefreshSelection;

@property (nonatomic ,assign ,readonly) BOOL reachMaxSelectCount;

@property (nonatomic ,assign ,readonly) DWAlbumMediaOption selectionOption;

@property (nonatomic ,assign) BOOL useOriginImage;

@property (nonatomic ,copy) DWAlbumSelectionAction reachMaxSelectCountAction;

@property (nonatomic ,copy) DWAlbumSelectionAction sendAction;

-(instancetype)initWithMaxSelectCount:(NSInteger)maxSelectCount;

-(BOOL)addSelection:(PHAsset *)asset mediaIndex:(NSInteger)mediaIndex mediaOption:(DWAlbumMediaOption)mediaOption;

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

@property (nonatomic ,assign) DWAlbumMediaOption mediaOption;

@property (nonatomic ,strong) id userInfo;

@end

NS_ASSUME_NONNULL_END
