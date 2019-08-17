//
//  DWFixAdjustContentOffsetCollectionView.h
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/8/4.
//

///DWFixAdjustConllectionView是为了处理collectionView旋屏时为保证当前位置不变而重写了两个方法，具体缘由请看实现文件中的注释。

#import <UIKit/UIKit.h>

@interface DWFixAdjustCollectionView : UICollectionView

@property (nonatomic ,assign) BOOL dw_autoFixContentOffset;

@end
