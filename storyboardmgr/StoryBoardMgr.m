//
//  StoryBoardMgr.m
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "StoryBoardMgr.h"

@implementation StoryBoardMgr

#pragma mark - public
+ (id)viewControllerInCameraStoryboard:(NSString *)identifier {
    return [self.cameraStoryboard instantiateViewControllerWithIdentifier:identifier];
}

+ (id)viewControllerInOpenglStoryboard:(NSString *)identifier {
    return [self.openglStoryboard instantiateViewControllerWithIdentifier:identifier];
}

+ (id)viewControllerInScriptStoryboard:(NSString *)identifier {
    return [self.scriptStoryboard instantiateViewControllerWithIdentifier:identifier];
}

+ (id)viewControllerInReplayStoryboard:(NSString *)identifier {
    return [self.replayStoryboard instantiateViewControllerWithIdentifier:identifier];
}


#pragma mark - private
+ (UIStoryboard *)cameraStoryboard {
    return [UIStoryboard storyboardWithName:@"Camera" bundle:nil];
}

+ (UIStoryboard *)openglStoryboard {
    return [UIStoryboard storyboardWithName:@"Opengl" bundle:nil];
}

+ (UIStoryboard *)scriptStoryboard {
    return [UIStoryboard storyboardWithName:@"Script" bundle:nil];
}

+ (UIStoryboard *)replayStoryboard {
    return [UIStoryboard storyboardWithName:@"Replay" bundle:nil];
}


@end
