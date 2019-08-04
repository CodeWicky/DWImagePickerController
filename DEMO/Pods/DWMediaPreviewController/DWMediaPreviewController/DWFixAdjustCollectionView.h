//
//  DWFixAdjustContentOffsetCollectionView.h
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/8/4.
//

///DWFixAdjustConllectionView是为了处理collectionView在当前为最后一个cell，且旋屏时为保证当前位置不变而内部调用 -setContentOffset: ，但是由于尺寸改变还会自动调用 -adjustContentOffsetIfNecessary 方法，此方法也会调用 -setContentOffset: ，由于两个都具有动画，最后导致位置异常。所以此子类内部重写了 -adjustContentOffsetIfNecessary 方法，避免此问题。

#import <UIKit/UIKit.h>

@interface DWFixAdjustCollectionView : UICollectionView

@property (nonatomic ,assign) BOOL dw_ignoreAdjustContentOffset;

@end
