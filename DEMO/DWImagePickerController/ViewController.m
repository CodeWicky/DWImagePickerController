//
//  ViewController.m
//  DWAlbumPickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWAlbumManager.h"
#import "DWImagePickerController.h"
#import <DWImagePickerController/DWAlbumToolBar.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor greenColor];
    
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wunused-variable"
//    DWImagePickerController * picker = [DWImagePickerController  showImagePickerWithAlbumManager:nil option:nil currentVC:self];
//#pragma clang diagnostic pop
    DWImagePickerController * picker = [[DWImagePickerController alloc] initWithAlbumManager:nil option:nil columnCount:3 spacing:5];
    picker.maxSelectCount = 9;
    [picker fetchCameraRollWithCompletion:^{
        [self presentViewController:picker animated:YES completion:nil];
    }];
    
}


@end
