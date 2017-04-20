//
//  CapturePreviewViewController.m
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "CapturePreviewViewController.h"

@interface CapturePreviewViewController ()

@property (nonatomic, weak) IBOutlet UIView* mainView;

@end

@implementation CapturePreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - actions
- (IBAction)onTouchUpInside_StartCapture:(id)sender {
    
}

- (IBAction)onTouchUpInside_StopCapture:(id)sender {
    
}

- (IBAction)onTouchUpInside_Close:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
