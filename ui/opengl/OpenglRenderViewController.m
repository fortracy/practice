//
//  OpenglRenderViewController.m
//  practicework
//
//  Created by bleach on 16/5/28.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "OpenglRenderViewController.h"
#import "GLRenderView.h"

@interface OpenglRenderViewController ()

@property (nonatomic, weak) IBOutlet GLRenderView* renderView;

@end

@implementation OpenglRenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self doInitComponent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)dealloc {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)doInitComponent {
    [_renderView startAnimation];
}

- (void)deInitComponent {
    [_renderView stopAnimation];
}

#pragma mark - Actions
- (IBAction)onTouchUpInside_Back:(id)sender {
    [self deInitComponent];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
