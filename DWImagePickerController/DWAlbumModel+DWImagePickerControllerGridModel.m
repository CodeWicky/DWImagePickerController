//
//  DWAlbumModel+DWImagePickerControllerGridModel.m
//  DWAlbumGridController
//
//  Created by Wicky on 2020/3/2.
//

#import <objc/runtime.h>
#import "DWAlbumModel+DWImagePickerControllerGridModel.h"

@implementation DWAlbumModel (DWImagePickerControllerGridModel)

-(void)autoFetchGridModelBackground {
    dispatch_async(self.fetchDataQueue, ^{
        [self fetchGridModelWithCompletion:nil];
    });
}

-(void)fetchGridModelWithCompletion:(void (^)(DWAlbumGridModel * gridModel))completion {
    if (self.userInfo) {
        if (completion) {
            completion(self.userInfo);
        }
    } else {
        if (self.loader) {
            self.userInfo = self.loader(self);
        }
        if (completion) {
            completion(self.userInfo);
        }
    }
}

-(void)clearGridModelCache {
    self.userInfo = nil;
}

#pragma mark --- setter/getter ---
-(DWImagePickerControllerGridModelLoader)loader {
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setLoader:(DWImagePickerControllerGridModelLoader)loader {
    objc_setAssociatedObject(self, @selector(loader), loader, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(dispatch_queue_t)fetchDataQueue {
    dispatch_queue_t q = objc_getAssociatedObject(self, _cmd);
    if (!q) {
        q = dispatch_queue_create("com.DWImagePickerController.AlbumModel.fetchDataSourceQueue", NULL);
        objc_setAssociatedObject(q, _cmd, q, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return q;
}

@end
