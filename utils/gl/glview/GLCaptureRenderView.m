//
//  GLCaptureRenderView.m
//  practicework
//
//  Created by bleach on 16/5/31.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLCaptureRenderView.h"
#import "GLCaptureRenderer.h"

@implementation GLCaptureRenderView

- (void)doHavePrimePower {
    isPrimePower = NO;
}

- (BOOL)doInitRenderer {
    return YES;
}

- (void)doDrawingWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (isPrimePower) {
        return;
    }
    EAGLContext* oldContext = [EAGLContext currentContext];
    if (oldContext != glContext) {
        if (![EAGLContext setCurrentContext:glContext]) {
            return;
        }
    }
    
    if (renderer == NULL) {
        [self doInitRenderer];
    }
    //真正渲染数据
    if (renderer) {
        [renderer renderWithPixelBuffer:pixelBuffer];
//        [renderer renderOffscreenWithPixelBuffer:pixelBuffer];
//        [renderer renderOffsreenToScreen];
    }
    
    if (oldContext != glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
}

@end
