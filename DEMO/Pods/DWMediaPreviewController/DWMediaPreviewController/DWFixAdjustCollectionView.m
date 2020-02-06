//
//  DWFixAdjustContentOffsetCollectionView.m
//  DWMediaPreviewController
//
//  Created by Wicky on 2019/8/4.
//

#import "DWFixAdjustCollectionView.h"
#import <DWKit/NSArray+DWArrayUtils.h>

@interface UICollectionView (DWFixAdjust)

-(void)_adjustContentOffsetIfNecessary;

@end

@implementation DWFixAdjustCollectionView

-(void)_adjustContentOffsetIfNecessary {
    ///重写这里是因为，在旋转屏幕的时候，由于contentSize改变了，系统会默认调用此内部方法，然而当当前展示的cell时collectionView的最后一个cell时，若此时旋屏，在默认调整一次contentOffset后系统又自动触发此方法，连续两次有动画的调整位置且时间上具有重叠，导致位置错误。故此处重写此方法来避免此问题。
    if (!self.dw_autoFixContentOffset) {
        [super _adjustContentOffsetIfNecessary];
    }
}

-(void)setFrame:(CGRect)frame {
    ///这里之所以重写是因为:
    ///1.在此控制器不处于导航控制器中时，当旋屏时调用栈为
    ///setFrame: -> _adjustContentOffsetIfNecessary -> setContentOffset: (此方法为_adjustContentOffsetIfNecessary内部调用) -> setContentOffset: (此方法为setFrame:内部在_adjustContentOffsetIfNecessary之后的调用，也就是说这种情况会连续调用两次) -> updateVisibleCells -> setContentOffset: -> _adjustContentOffsetIfNecessary -> setContentOffset:
    ///2.在此控制器处于导航控制器中时，当旋屏时调用栈为
    ///setFrame: -> _adjustContentOffsetIfNecessary -> setContentOffset: (此方法为_adjustContentOffsetIfNecessary内部调用) -> updateVisibleCells -> setContentOffset: -> _adjustContentOffsetIfNecessary -> setContentOffset:
    ///通过对比可以发现，当控制器处于导航控制器中时，旋屏时会少触发一个有setFrame:内部调用的setContentOffset: 。这是前提，我们继续分析数据。
    ///通过断点调试追踪每次setContentOffset:的值时发现
    ///1.第一次调用的_adjustContentOffsetIfNecessary 引起的setContentOffset: 的值是错误的。
    ///2.第二次直接由setFrame: 引起的setContentOffset:的值是正确的，可以保证当前展示的cell不变
    ///3.第三次由updateVisibleCells引起的setContentOffset:与updateVisibleCells调用之前保持一致。
    ///4.第四次由_adjustContentOffsetIfNecessary引起的setContentOffset:仍与本次_adjustContentOffsetIfNecessary调用前保持一致。
    
    ///所以我们可以发现，若控制器处于导航控制器中时，缺少了setFrame:引起的setContentOffset: 则缺少了一次设置为当前cell不变的尺寸，所以无论是否屏蔽第一次_adjustContentOffsetIfNecessary都会导致旋屏后的位置不正确（因为第一次由setFrame:引起的_adjustContentOffsetIfNecessary从而引起的setContentOffset:的值均不正确，在无导航时由于第一次及第二次setContentOffset均调用，且值不相同，故导致最终位置不正确。所以当没有导航时屏蔽第一次调用有效。）。综上所述，兼容无论是否有导航控制器，所以我们的解决方案为在调用setFrame: 之前先将contentOffset设置为保持当前cell的位置，同时屏蔽第一次由setFrame:引起的_adjustContentOffsetIfNecessary，这样既可保证无论是否具有导航控制器，旋屏以后均可以正常展示。
    
    ///后续应考虑修改此设置contentOffset:至即将旋屏的代理中，且当前展示的cell计算方式应该改为根据visibleCells计算，今天太晚了，明天再改。
    ///第二天我又来了，这里尝试将此处逻辑移至旋屏代理失败。主要是因为willTransition内部应该未直接调用setFrame:。故当移至代理中时可以看到明显的cell滚动的动作。分析应该是由于两次设置的offset值不同且具有动画导致的看到滚动动作。所以这里后续还是考虑根据visibleCells计算index来做进一步优化吧。
    
    ///是的，今天第三天。后续要改成按照visibleCells计算，首先就要取到之前的第一个cell，然后保证旋屏之后还是第一个即可。所以这里要获取旋屏后指定indexPath的cell的frame信息，故要求先调用super，再修正contentOffset。所以这里做了改造，修改了dw_autoFixContentOffset置NO的时机及index计算的方式。总算调节完了。
    
    ///最后一改，去掉不必要约束，pagingEnabled。
    NSIndexPath * oriFirstIdp = nil;
    if (self.dw_autoFixContentOffset) {
        NSArray <UICollectionViewLayoutAttributes *>* attrsInRect = [self.collectionViewLayout layoutAttributesForElementsInRect:(CGRect){self.contentOffset,self.frame.size}];
        __block NSIndexPath * tmp = attrsInRect.firstObject.indexPath;
        [attrsInRect enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.indexPath.row < tmp.row) {
                tmp = obj.indexPath;
            }
        }];
        oriFirstIdp = tmp;
    }
    
    [super setFrame:frame];
    if (self.dw_autoFixContentOffset) {
        self.dw_autoFixContentOffset = NO;
        if (!oriFirstIdp) {
            return;
        }
        UICollectionViewLayoutAttributes * attr = [self layoutAttributesForItemAtIndexPath:oriFirstIdp];
        CGPoint fixContentOffset = CGPointZero;
        if (((UICollectionViewFlowLayout *)self.collectionViewLayout).scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            fixContentOffset.x = attr.frame.origin.x;
            if (@available(iOS 11.0,*)) {
                fixContentOffset.x -= self.adjustedContentInset.left;
            }
        } else {
            fixContentOffset.y = attr.frame.origin.y;
            if (@available(iOS 11.0,*)) {
                fixContentOffset.y -= self.adjustedContentInset.top;
            }
        }
        [self setContentOffset:fixContentOffset];
    }
}

-(void)setContentOffset:(CGPoint)contentOffset {
    [super setContentOffset:contentOffset];
}

@end
