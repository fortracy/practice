//
//  MainMenuTableViewController.h
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XlbPracticeType)
{
    XlbPracticeTypeCameraPreview = 0,           //摄像头预览
    XlbPracticeTypeGLRenderView = 1,            //Opengl渲染
    XlbPracticeTypeGLParticelRenderView = 2,    //粒子效果
    XlbPracticeTypeSpiderMonkeyView = 3,        //SpiderMonkey
    XlbPracticeTypeReplayView = 4,              //手游直播
    XlbPracticeTypeMaxCount,                    //总数
};

@interface MainMenuTableViewController : UITableViewController

@end
