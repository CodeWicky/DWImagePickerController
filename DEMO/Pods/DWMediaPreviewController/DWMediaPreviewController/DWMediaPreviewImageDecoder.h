//
//  DWMediaPreviewImageDecoder.h
//  DWKit
//
//  Created by Wicky on 2020/2/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^DWMediaPreviewImageDecoderCompletion)(UIImage * image);
@interface DWMediaPreviewImageDecoder : NSObject

+(void)decodeImage:(UIImage *)image completion:(DWMediaPreviewImageDecoderCompletion)completion;

+(BOOL)imageDecoded:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
