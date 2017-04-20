//
//  OpenglParticleViewController.m
//  practicework
//
//  Created by bleach on 16/6/19.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "OpenglParticleViewController.h"
#import "GLParticelRenderView.h"

@interface OpenglParticleViewController ()

@property (nonatomic, weak) IBOutlet GLParticelRenderView* renderView;

@end

@implementation OpenglParticleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self doInitComponent];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    
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
