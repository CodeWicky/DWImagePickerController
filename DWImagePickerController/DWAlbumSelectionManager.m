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

-(void)addSelection:(DWImageAssetModel *)asset {
    if (asset) {
        if ((self.maxSelectCount > 0 && self.selections.count < self.maxSelectCount) || self.maxSelectCount <= 0) {
            DWAlbumSelectionModel * model = [DWAlbumSelectionModel new];
            model.asset = asset;
            [self.selections addObject:model];
        }
    }
}

-(void)removeSelection:(DWImageAssetModel *)asset {
    NSInteger idx = [self indexOfSelection:asset];
    if (idx != NSNotFound) {
        [self.selections removeObjectAtIndex:idx];
    }
}

-(void)removeSelectionAtIndex:(NSInteger)index {
    if (index < self.selections.count) {
        [self.selections removeObjectAtIndex:index];
    }
}

-(NSInteger)indexOfSelection:(DWImageAssetModel *)asset {
    __block NSInteger index = NSNotFound;
    [self.selections enumerateObjectsUsingBlock:^(DWAlbumSelectionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.asset isEqual:asset]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

#pragma mark --- setter/getter ---
-(NSMutableArray<DWAlbumSelectionModel *> *)selections {
    if (!_selections) {
        _selections = [NSMutableArray arrayWithCapacity:self.maxSelectCount];
    }
    return _selections;
}

@end

@implementation DWAlbumSelectionModel

@end
