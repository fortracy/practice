//
//  GLParticelRenderView.m
//  practicework
//
//  Created by bleach on 16/6/19.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLParticelRenderView.h"
#import "GLParticelRenderer.h"

@implementation GLParticelRenderView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self doInitGesuture];
}

- (void)doHavePrimePower {
    isPrimePower = YES;
}

- (BOOL)doInitRenderer {
    renderer = [[GLParticelRenderer alloc] initWithContext:glContext AndDrawable:(id<EAGLDrawable>)self.layer];
    if (!renderer) {
        return NO;
    }
    
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
    }
    
    if (oldContext != glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
}

- (void)doInitGesuture {
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addPraise)];
    [self addGestureRecognizer:tap];
}

- (void)addPraise {
//    [self setFrame:CGRectMake(0.0f, 0.0f, 300, 300)];
//    [((GLParticelRenderer *)renderer) updateResize];
    [((GLParticelRenderer *)renderer) addParticelV3];
}

@end
