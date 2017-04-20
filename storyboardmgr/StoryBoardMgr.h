//
//  StoryBoardMgr.h
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StoryBoardMgr : NSObject

+ (id)viewControllerInCameraStoryboard:(NSString *)identifier;
+ (id)viewControllerInOpenglStoryboard:(NSString *)identifier;
+ (id)viewControllerInScriptStoryboard:(NSString *)identifier;
+ (id)viewControllerInReplayStoryboard:(NSString *)identifier;

@end
