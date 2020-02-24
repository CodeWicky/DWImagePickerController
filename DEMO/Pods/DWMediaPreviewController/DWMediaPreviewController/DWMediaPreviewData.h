//
//  DWMediaPreviewData.h
//  DWKit
//
//  Created by Wicky on 2020/2/24.
//

#import <Foundation/Foundation.h>
#import <YYImage/YYImage.h>
typedef NS_ENUM(NSUInteger, DWMediaPreviewType) {
    DWMediaPreviewTypeNone,
    DWMediaPreviewTypeImage,
    DWMediaPreviewTypeAnimateImage,
    DWMediaPreviewTypeLivePhoto API_AVAILABLE(macos(10.15), ios(9.1), tvos(10)),
    DWMediaPreviewTypeVideo,
    DWMediaPreviewTypeCustomize,
};

NS_ASSUME_NONNULL_BEGIN

@interface DWMediaPreviewData : NSObject

@property (nonatomic ,strong) UIImage * previewImage;

@property (nonatomic ,strong) id media;

@property (nonatomic ,strong) YYImage * animateImage;

@property (nonatomic ,assign) DWMediaPreviewType previewType;

@property (nonatomic ,assign) BOOL shouldShowBadge;

@property (nonatomic ,assign) BOOL isHDR;

@property (nonatomic ,assign) BOOL shouldShowProgressIndicator;

@property (nonatomic ,strong) id userInfo;

@end

NS_ASSUME_NONNULL_END
