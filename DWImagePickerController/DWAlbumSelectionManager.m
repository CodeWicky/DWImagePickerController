//
//  DWAlbumSelectionManager.m
//  DWCheckBox
//
//  Created by Wicky on 2020/1/3.
//

#import "DWAlbumSelectionManager.h"



@implementation DWAlbumSelectionManager

#pragma mark --- interface method ---
-(instancetype)initWithMaxSelectCount:(NSInteger)maxSelectCount {
    if (self = [super init]) {
        _maxSelectCount = maxSelectCount;
    }
    return self;
}

-(BOOL)addSelection:(PHAsset *)asset mediaIndex:(NSInteger)mediaIndex previewType:(DWMediaPreviewType)previewType {
    if (asset) {
        if (!self.reachMaxSelectCount) {
            DWAlbumSelectionModel * model = [DWAlbumSelectionModel new];
            model.asset = asset;
            model.mediaIndex = mediaIndex;
            model.previewType = previewType;
            [self.selections addObject:model];
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
    NSInteger idx = [self indexOfSelection:asset];
    if (idx != NSNotFound) {
        [self.selections removeObjectAtIndex:idx];
        [self handleSetNeedsRefreshSelection];
        return YES;
    }
    return NO;
}

-(BOOL)removeSelectionAtIndex:(NSInteger)index {
    if (index < self.selections.count) {
        [self.selections removeObjectAtIndex:index];
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

@end

@implementation DWAlbumSelectionModel

@end
