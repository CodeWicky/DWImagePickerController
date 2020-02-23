//
//  DWAlbumSelectionManager.m
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import "DWAlbumSelectionManager.h"

@interface DWAlbumSelectionCounter : NSObject

@property (nonatomic ,assign) NSInteger imageCount;

@property (nonatomic ,assign) NSInteger animateImageCount;

@property (nonatomic ,assign) NSInteger livePhotoCount;

@property (nonatomic ,assign) NSInteger videoCount;

@property (nonatomic ,assign) DWAlbumMediaOption mediaOption;

@end

@interface DWAlbumSelectionManager ()

@property (nonatomic ,strong) DWAlbumSelectionCounter * counter;

@end

@implementation DWAlbumSelectionManager

#pragma mark --- interface method ---
-(instancetype)initWithMaxSelectCount:(NSInteger)maxSelectCount {
    if (self = [super init]) {
        _maxSelectCount = maxSelectCount;
    }
    return self;
}

-(BOOL)addSelection:(PHAsset *)asset mediaIndex:(NSInteger)mediaIndex mediaOption:(DWAlbumMediaOption)mediaOption {
    if (asset) {
        if (!self.reachMaxSelectCount) {
            DWAlbumSelectionModel * model = [DWAlbumSelectionModel new];
            model.asset = asset;
            model.mediaIndex = mediaIndex;
            model.mediaOption = mediaOption;
            [self.selections addObject:model];
            [self addMediaOption:mediaOption];
            [self handleSetNeedsRefreshSelection];
            return YES;
        }
        
        if (self.reachMaxSelectCountAction) {
            self.reachMaxSelectCountAction(self);
        }
    }
    
    return NO;
}

-(void)addUserInfo:(id)userInfo forAsset:(PHAsset *)asset {
    NSInteger index = [self indexOfSelection:asset];
    [self addUserInfo:userInfo atIndex:index];
}

-(void)addUserInfo:(id)userInfo atIndex:(NSInteger)index {
    if (index < self.selections.count) {
        DWAlbumSelectionModel * model = [self.selections objectAtIndex:index];
        model.userInfo = userInfo;
    }
}

-(BOOL)removeSelection:(PHAsset *)asset {
    DWAlbumSelectionModel * model = [self selectionModelForSelection:asset];
    if (model) {
        [self.selections removeObject:model];
        [self removeMediaOption:model.mediaOption];
        [self handleSetNeedsRefreshSelection];
        return YES;
    }
    return NO;
}

-(BOOL)removeSelectionAtIndex:(NSInteger)index {
    DWAlbumSelectionModel * model = [self selectionModelAtIndex:index];
    if (model) {
        [self.selections removeObjectAtIndex:index];
        [self removeMediaOption:model.mediaOption];
        [self handleSetNeedsRefreshSelection];
        return YES;
    }
    return NO;
}

-(NSInteger)indexOfSelection:(PHAsset *)asset {
    __block NSInteger index = NSNotFound;
    [self.selections enumerateObjectsUsingBlock:^(DWAlbumSelectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.asset isEqual:asset]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

-(DWAlbumSelectionModel *)selectionModelAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.selections.count) {
        return [self.selections objectAtIndex:index];
    }
    return nil;
}

-(DWAlbumSelectionModel *)selectionModelForSelection:(PHAsset *)asset {
    if (!asset) {
        return nil;
    }
    NSInteger index = [self indexOfSelection:asset];
    if (index == NSNotFound) {
        return nil;
    }
    return [self selectionModelAtIndex:index];
}

-(PHAsset *)selectionAtIndex:(NSInteger)index {
    return [self selectionModelAtIndex:index].asset;
}

-(void)finishRefreshSelection {
    _needsRefreshSelection = NO;
}

#pragma mark --- tool method ---
-(void)handleSetNeedsRefreshSelection {
    _needsRefreshSelection = YES;
}

-(void)addMediaOption:(DWAlbumMediaOption)mediaOption {
    switch (mediaOption) {
        case DWAlbumMediaOptionImage:
        {
            self.counter.imageCount ++;
        }
            break;
        case DWAlbumMediaOptionAnimateImage:
        {
            self.counter.animateImageCount ++;
        }
            break;
        case DWAlbumMediaOptionLivePhoto:
        {
            self.counter.livePhotoCount ++;
        }
            break;
        case DWAlbumMediaOptionVideo:
        {
            self.counter.videoCount ++;
        }
            break;
        default:
            break;
    }
    [self refreshMediaOption];
}

-(void)removeMediaOption:(DWAlbumMediaOption)mediaOption {
    switch (mediaOption) {
        case DWAlbumMediaOptionImage:
        {
            self.counter.imageCount --;
        }
            break;
        case DWAlbumMediaOptionAnimateImage:
        {
            self.counter.animateImageCount --;
        }
            break;
        case DWAlbumMediaOptionLivePhoto:
        {
            self.counter.livePhotoCount --;
        }
            break;
        case DWAlbumMediaOptionVideo:
        {
            self.counter.videoCount --;
        }
            break;
        default:
            break;
    }
    [self refreshMediaOption];
}

-(void)refreshMediaOption {
    _selectionOption = self.counter.mediaOption;
}

#pragma mark --- setter/getter ---
-(NSMutableArray<DWAlbumSelectionModel *> *)selections {
    if (!_selections) {
        _selections = [NSMutableArray arrayWithCapacity:self.maxSelectCount];
    }
    return _selections;
}

-(BOOL)reachMaxSelectCount {
    if (self.maxSelectCount > 0) {
        return self.selections.count >= self.maxSelectCount;
    }
    return NO;
}

-(DWAlbumSelectionCounter *)counter {
    if (!_counter) {
        _counter = [DWAlbumSelectionCounter new];
    }
    return _counter;
}

@end

@implementation DWAlbumSelectionModel

@end

@implementation DWAlbumSelectionCounter

-(DWAlbumMediaOption)mediaOption {
    DWAlbumMediaOption opt = DWAlbumMediaOptionUndefine;
    if (self.imageCount > 0) {
        opt |= DWAlbumMediaOptionImage;
    }
    if (self.animateImageCount > 0) {
        opt |= DWAlbumMediaOptionAnimateImage;
    }
    if (self.livePhotoCount > 0) {
        opt |= DWAlbumMediaOptionLivePhoto;
    }
    if (self.videoCount > 0) {
        opt |= DWAlbumMediaOptionVideo;
    }
    return opt;
}

@end
