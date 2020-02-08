//
//  DWFixAdjustContentOffsetCollectionView.h
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/8/4.
//

///DWFixAdjustConllectionView是为了处理collectionView旋屏时为保证当前位置不变而重写了两个方法，具体缘由请看实现文件中的注释。

//两种正确的使用方式：
//第一种方式
//当collectionView的adjustedContentInset始终为UIEdgeInsetsZero且collectionView使用autoLayout或autoresizingMask不为None时：
//1.仅需在将要旋屏代理中设置dw_autoFixContentOffset为YES

//第二种方式
//当collectionView的adjustedContentInset有值且非0或者collectionView使用frame布局时：
//1.在将要旋屏代理中设置dw_autoFixContentOffset为YES
//2.在将要旋屏代理中设置dw_useAutoFixAdjustedContentInset为YES
//3.在将要旋屏代理中设置dw_autoFixAdjustedContentInset为旋屏前collectionView的adjustedContentInset。
//4.在safeArea改变完成或者旋屏完成代理中，设置frame

#import <UIKit/UIKit.h>

@interface DWFixAdjustCollectionView : UICollectionView

///是否开启自动调整contentOffset以保证当前展示内容不变。默认为NO，使用时开启，且仅有效一次。再用再打开。
@property (nonatomic ,assign) BOOL dw_autoFixContentOffset;

///若使用自动调整时，预设的调整前的adjustedContentInset值。适合配合第二种使用方式使用。
@property (nonatomic ,assign) UIEdgeInsets dw_autoFixAdjustedContentInset;

///是否使用预设的adjustedContentInset。若不使用，将使用collectionView当前值。默认为NO，使用时开启，且仅一次有效。再用再打开。
@property (nonatomic ,assign) BOOL dw_useAutoFixAdjustedContentInset;

@end
