//
//  OpenglBaseViewController.m
//  practicework
//
//  Created by bleach on 16/5/30.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "OpenglBaseViewController.h"

@interface OpenglBaseViewController ()

@end

@implementation OpenglBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:YES];
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
