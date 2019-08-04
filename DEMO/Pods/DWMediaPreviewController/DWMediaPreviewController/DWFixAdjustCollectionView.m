//
//  DWFixAdjustContentOffsetCollectionView.m
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/8/4.
//

#import "DWFixAdjustCollectionView.h"

@interface UICollectionView (DWFixAdjust)

-(void)_adjustContentOffsetIfNecessary;

@end

@implementation DWFixAdjustCollectionView

-(void)_adjustContentOffsetIfNecessary {
    ///重写这里是因为，在旋转屏幕的时候，由于contentSize改变了，系统会默认调用此内部方法，然而当当前展示的cell时collectionView的最后一个cell时，若此时旋屏，在默认调整一次contentOffset后系统又自动触发此方法，连续两次有动画的调整位置且时间上具有重叠，导致位置错误。故此处重写此方法来避免此问题。
    if (self.dw_ignoreAdjustContentOffset) {
        self.dw_ignoreAdjustContentOffset = NO;
    } else {
        [super _adjustContentOffsetIfNecessary];
    }
}

@end
