//
//  DWMediaPreviewImageDecoder.m
//  DWKit
//
//  Created by Wicky on 2020/2/4.
//

#import "DWMediaPreviewImageDecoder.h"
#import <YYImage/YYImageCoder.h>
@interface DWMediaPreviewImageDecoder()

@property (nonatomic ,strong) NSCache * decodedImageCache;

@property (nonatomic ,strong) dispatch_queue_t decodeQueue;

@end

@implementation DWMediaPreviewImageDecoder

#pragma mark --- interface method ---
+(void)decodeImage:(UIImage *)image completion:(DWMediaPreviewImageDecoderCompletion)completion {
    if (!image) {
        return ;
    }
    
    DWMediaPreviewImageDecoder * d = [self decoder];
    __block UIImage * cachedImage = [d.decodedImageCache objectForKey:image];
    if (cachedImage) {
        if (completion) {
            completion(cachedImage);
        }
    } else {
        dispatch_async(d.decodeQueue, ^{
            @autoreleasepool{
                cachedImage = image.yy_imageByDecoded;
                [d.decodedImageCache setObject:cachedImage forKey:image];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(cachedImage);
                    }
                });
            }
        });
    }
}

+(BOOL)imageDecoded:(UIImage *)image {
    if (!image) {
        return NO;
    }
    DWMediaPreviewImageDecoder * d = [self decoder];
    return ([d.decodedImageCache objectForKey:image] != nil);
}

#pragma mark --- tool method ---
+(instancetype)decoder {
    static DWMediaPreviewImageDecoder * d = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        d = [self new];
    });
    return d;
}

#pragma mark --- setter/getter ---
-(NSCache *)decodedImageCache {
    if (!_decodedImageCache) {
        _decodedImageCache = [[NSCache alloc] init];
    }
    return _decodedImageCache;
}

-(dispatch_queue_t)decodeQueue {
    if (!_decodeQueue) {
        _decodeQueue = dispatch_queue_create("com.wicky.DWMediaPreviewcontroller.imageDecodeQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _decodeQueue;
}

@end
