//
//  ReplayBroadcastViewController.m
//  practicework
//
//  Created by bleach on 2017/1/16.
//  Copyright © 2017年 duowan. All rights reserved.
//

#import "ReplayBroadcastViewController.h"
#import <ReplayKit/ReplayKit.h>

@interface ReplayBroadcastViewController ()<RPBroadcastActivityViewControllerDelegate>

@end

@implementation ReplayBroadcastViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onLiveButtonPressed:(id)sender {
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
        broadcastActivityViewController = broadcastActivityViewController;
        broadcastActivityViewController.delegate = self;
        [self presentViewController:broadcastActivityViewController animated:YES completion:nil];
    }];
}


#pragma mark - RPBroadcastActivityViewControllerDelegate
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error {
    
    [broadcastActivityViewController dismissViewControllerAnimated:YES completion:nil];
    
    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"startBroadcastWithHandler");
        } else {
            NSLog(@"startBroadcastWithHandler error: %@", error);
        }
    }];
}

- (IBAction)onCancelButtonPressed:(id)sender {
    [self userDidCancelSetup];
}

- (IBAction)onOKButtonPressed:(id)sender {
    [self userDidFinishSetup];
}


#pragma mark - Private

// Called when the user has finished interacting with the view controller and a broadcast stream can start
- (void)userDidFinishSetup {
    
    NSLog(@"userDidFinishSetup");
    
    // Broadcast url that will be returned to the application
    NSURL *broadcastURL = [NSURL URLWithString:@"http://broadcastURL_example/stream1"];
    
    // Set broadcast settings
    RPBroadcastConfiguration *broadcastConfig = [[RPBroadcastConfiguration alloc] init];
    broadcastConfig.clipDuration = 5.0; // deliver movie clips every 5 seconds
    
    // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
    [self.extensionContext completeRequestWithBroadcastURL:broadcastURL broadcastConfiguration:broadcastConfig setupInfo:nil];
}

- (void)userDidCancelSetup {
    // Tell ReplayKit that the extension was cancelled by the user
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"YourAppDomain" code:-1     userInfo:nil]];
}
@end
