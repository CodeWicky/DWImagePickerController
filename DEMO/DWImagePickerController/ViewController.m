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
#import <DWImagePickerController/DWAlbumPreviewToolBar.h>

@interface ViewController ()

@property (nonatomic ,strong) DWAlbumPreviewToolBar * toolBar;

@property (nonatomic ,strong) DWAlbumSelectionManager * mgr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor greenColor];
//    [self.view addSubview:self.toolBar];
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wunused-variable"
//    DWImagePickerController * picker = [DWImagePickerController  showImagePickerWithAlbumManager:nil option:nil currentVC:self];
//#pragma clang diagnostic pop
    DWImagePickerConfiguration * conf = [DWImagePickerConfiguration new];
    conf.displayMediaOption = DWAlbumMediaOptionVideo;
    DWImagePickerController * picker = [[DWImagePickerController alloc] initWithAlbumManager:nil fetchOption:nil pickerConfiguration:conf columnCount:3 spacing:5];
    picker.maxSelectCount = 9;
    [picker fetchCameraRollWithCompletion:^{
        [self presentViewController:picker animated:YES completion:nil];
    }];
    
//    if (self.mgr.selections.count == 0) {
//        PHAsset * asset = [PHAsset new];
//        if ([self.mgr addSelection:asset mediaIndex:0 previewType:(DWMediaPreviewTypeImage)]) {
//            [self.toolBar refreshUI];
//        }
//    } else {
//        if ([self.mgr removeSelectionAtIndex:0]) {
//            [self.toolBar refreshUI];
//        }
//    }
    
}

-(DWAlbumPreviewToolBar *)toolBar {
    if (!_toolBar) {
        _toolBar = [DWAlbumPreviewToolBar toolBar];
        [_toolBar configWithSelectionManager:self.mgr];
    }
    return _toolBar;
}

-(DWAlbumSelectionManager *)mgr {
    if (!_mgr) {
        _mgr = [[DWAlbumSelectionManager alloc] initWithMaxSelectCount:9 selectableOption:(DWAlbumMediaOptionAll) multiTypeSelectionEnable:YES];
    }
    return _mgr;
}

@end
