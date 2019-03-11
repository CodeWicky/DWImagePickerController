//
//  DWImageManager.m
//  DWImagePickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWImageManager.h"

@implementation DWImageManager

#pragma mark --- interface method ---
-(PHAuthorizationStatus)authorizationStatus {
    return [PHPhotoLibrary authorizationStatus];
}

-(void)requestAuthorization:(void (^)(PHAuthorizationStatus))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
}

@end
