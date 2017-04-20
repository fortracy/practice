//
//  MainMenuTableViewController.m
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "MainMenuTableViewController.h"
#import "StoryBoardMgr.h"
#import "CapturePreviewViewController.h"
#import "OpenglRenderViewController.h"
#import "OpenglParticleViewController.h"
#import "SpiderMonkeyViewController.h"
#import "ReplayBroadcastViewController.h"

@interface MainMenuTableViewController ()

@end

@implementation MainMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = NSLocalizedString(@"功能测试列表", nil);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return XlbPracticeTypeMaxCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [NSString stringWithFormat:@"mainMenuPracticeCell"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSInteger row = indexPath.row;
    switch (row) {
        case XlbPracticeTypeCameraPreview:
            cell.textLabel.text = NSLocalizedString(@"摄像头", nil);
            break;
        case XlbPracticeTypeGLRenderView:
            cell.textLabel.text = NSLocalizedString(@"GL帧动画", nil);
            break;
        case XlbPracticeTypeGLParticelRenderView:
            cell.textLabel.text = NSLocalizedString(@"GL点赞", nil);
            break;
        case XlbPracticeTypeSpiderMonkeyView:
            cell.textLabel.text = NSLocalizedString(@"SpiderMonkey", nil);
            break;
        case XlbPracticeTypeReplayView:
            cell.textLabel.text = NSLocalizedString(@"ReplayKit", nil);
            break;
        default:
            cell.textLabel.text = @"";
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO];
    
    switch (row) {
        case XlbPracticeTypeCameraPreview:
            [self doXlbPracticeCameraPreview];
            break;
        case XlbPracticeTypeGLRenderView:
            [self doXlbPracticeGLRenderView];
            break;
        case XlbPracticeTypeGLParticelRenderView:
            [self doXlbParticleView];
            break;
        case XlbPracticeTypeSpiderMonkeyView:
            [self doXlbSpiderMonkey];
            break;
        case XlbPracticeTypeReplayView:
            [self doXlbReplayView];
            break;
        default:
            break;
    }
}

- (void)doXlbPracticeCameraPreview {
    CapturePreviewViewController* vc = [StoryBoardMgr viewControllerInCameraStoryboard:@"CapturePreviewViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)doXlbPracticeGLRenderView {
    //对于使用opengl的视图,显示着NavigationBar的话,会有很大的GPU消耗,所以如果是GPU相关的,需要隐藏NavigationBar
    OpenglRenderViewController* vc = [StoryBoardMgr viewControllerInOpenglStoryboard:@"OpenglRenderViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)doXlbParticleView {
    OpenglParticleViewController* vc = [StoryBoardMgr viewControllerInOpenglStoryboard:@"OpenglParticleViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)doXlbSpiderMonkey {
    SpiderMonkeyViewController* vc = [StoryBoardMgr viewControllerInScriptStoryboard:@"SpiderMonkeyViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)doXlbReplayView {
    ReplayBroadcastViewController* vc = [StoryBoardMgr viewControllerInReplayStoryboard:@"ReplayBroadcastViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)demo {
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i < 100; i++)
    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
            NSLog(@"%i",i);
            sleep(2);
            dispatch_semaphore_signal(semaphore);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

// Conversion from RGB to YUV420
int RGB2YUV_YR[256], RGB2YUV_YG[256], RGB2YUV_YB[256];
int RGB2YUV_UR[256], RGB2YUV_UG[256], RGB2YUV_UBVR[256];
int RGB2YUV_VG[256], RGB2YUV_VB[256];

//
// Table used for RGB to YUV420 conversion
//
void InitLookupTable()
{
    int i;
    
    for (i = 0; i < 256; i++) RGB2YUV_YR[i] = (float)65.481 * (i<<8);
    for (i = 0; i < 256; i++) RGB2YUV_YG[i] = (float)128.553 * (i<<8);
    for (i = 0; i < 256; i++) RGB2YUV_YB[i] = (float)24.966 * (i<<8);
    for (i = 0; i < 256; i++) RGB2YUV_UR[i] = (float)37.797 * (i<<8);
    for (i = 0; i < 256; i++) RGB2YUV_UG[i] = (float)74.203 * (i<<8);
    for (i = 0; i < 256; i++) RGB2YUV_VG[i] = (float)93.786 * (i<<8);
    for (i = 0; i < 256; i++) RGB2YUV_VB[i] = (float)18.214 * (i<<8);
    for (i = 0; i < 256; i++) RGB2YUV_UBVR[i] = (float)112 * (i<<8);
}
//
// Convert from RGB24 to YUV420
//
int ConvertRGB2YUV(int w,int h,unsigned char *rgb,unsigned char *yuv)
{
    int i = 0;
    int x = 0;
    int y = 0;
//    for (y = 0; y < h; y++) {
//        NSMutableString* uvString = [[NSMutableString alloc] init];
//        for (x = 0; x < w; x++) {
//            unsigned char y = ( ( 66*rgb[4*i] + 129*rgb[4*i+1] + 25*rgb[4*i+2] ) >> 8 ) + 16;
//            [uvString appendString:[NSString stringWithFormat:@"y = %d, ", y]];
//            i++;
//        }
//        NSLog(@"%@", uvString);
//    }
    
    // Cb/u and Cr/v
    i = 0;
    for (y = 0; y < h/2; y++) {
        NSMutableString* uvString = [[NSMutableString alloc] init];
        for (x = 0; x < w/2; x++) {
            unsigned char u = ( ( -38*rgb[4*i] + -74*rgb[4*i+1] + 112*rgb[4*i+2] ) >> 8 ) + 128;
            unsigned char v = ( ( 112*rgb[4*i] + -94*rgb[4*i+1] + -18*rgb[4*i+2] ) >> 8 ) + 128;
            [uvString appendString:[NSString stringWithFormat:@"u = %d, v = %d, ", u, v]];
            i++;
        }
        NSLog(@"%@", uvString);
    }
    return 1;
}

- (void)doTranslate {
    InitLookupTable();
    UIImage* image = [UIImage imageNamed:@"image"];
    SImageData* imageData = imageDataFromUIImage(image, YES);
    
    ConvertRGB2YUV(imageData->width, imageData->height, imageData->data, nil);
}

@end
