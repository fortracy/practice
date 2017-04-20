//
//  GLRenderView.h
//  practicework
//
//  Created by bleach on 16/5/29.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GLRenderFrameInterval) {
    GLRenderFrameIntervalUnknown = 0,               //未定义的渲染帧间隔
    GLRenderFrameInterval60 = 1,                    //每秒60帧渲染
    GLRenderFrameInterval30 = 2,                    //每秒30帧渲染
    GLRenderFrameInterval20 = 3,                    //每秒20帧渲染
    GLRenderFrameInterval15 = 4,                    //每秒15帧渲染

};

@class GLBaseRenderer;
@interface GLRenderView : UIView {
    //渲染者
    GLBaseRenderer* renderer;
    //渲染上下文
    EAGLContext* glContext;
    //原动力(为真,则有自己的渲染循环,为假,则由外部驱动)
    BOOL isPrimePower;
}

//设置渲染帧间隔(GLRenderFrameInterval)
@property (nonatomic, assign) GLRenderFrameInterval renderFrameInterval;

/**
 * 设置视图大小和是否使用原动力
 */
- (id)initWithFrame:(CGRect)frame;

/**
 * 启动动画主循环,只有使用原动力的时候才有用
 */
- (void)startAnimation;

/**
 * 停止动画主循环,只有使用原动力的时候才有用
 */
- (void)stopAnimation;

/**
 * 如果是外部动力,非原动力,调用此方法
 */
- (void)doDrawingWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
