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
    
    DWAlbumToolBar * toolBar = [DWAlbumToolBar toolBar];
    
    [self.view addSubview:toolBar];
    
    toolBar.previewAction = ^(DWAlbumBaseToolBar * _Nonnull toolBar) {
        NSLog(@"preview");
    };
    
    toolBar.originImageAction = ^(DWAlbumBaseToolBar * _Nonnull toolBar) {
        toolBar.selectionManager.useOriginImage = !toolBar.selectionManager.useOriginImage;
        [toolBar.selectionManager addSelection:[DWImageAssetModel new]];
        [toolBar refreshSelection];
    };
    
    toolBar.sendAction = ^(DWAlbumBaseToolBar * _Nonnull toolBar) {
        NSLog(@"send");
    };
    
    DWAlbumSelectionManager * mgr = [DWAlbumSelectionManager new];
    
    [toolBar configWithSelectionManager:mgr];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    DWImagePickerController * picker = [DWImagePickerController showImagePickerWithAlbumManager:nil option:nil currentVC:self];
#pragma clang diagnostic pop
    
    
}


@end
