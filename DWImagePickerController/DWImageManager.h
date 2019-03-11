//
//  DWImageManager.h
//  DWImagePickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWImageManager : NSObject

-(PHAuthorizationStatus)authorizationStatus;

-(void)requestAuthorization:(void(^)(PHAuthorizationStatus status))completion;

@end

NS_ASSUME_NONNULL_END
