//
//  GLRenderView.m
//  practicework
//
//  Created by bleach on 16/5/29.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLRenderView.h"
#import "GLImageRenderer.h"

@interface GLRenderView ()

@property (nonatomic, assign) GLint bufferWidth;
@property (nonatomic, assign) GLint bufferHeight;
@property (nonatomic, assign) GLuint frameBufferHandle;
@property (nonatomic, assign) GLuint colorBufferHandle;
//渲染动力源(原动力)
@property (nonatomic, strong) CADisplayLink* displayLink;
//渲染线程
@property (nonatomic, strong) dispatch_queue_t renderQueue;
@end

@implementation GLRenderView
@synthesize renderFrameInterval = _renderFrameInterval;

// 指定这个是为了CA的渲染可以返回到视图上
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (![self doinit]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        if (![self doinit]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)doinit {
    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking  :   @(NO),
                                      kEAGLDrawablePropertyColorFormat      :   kEAGLColorFormatRGBA8 };
    
    _renderFrameInterval = GLRenderFrameInterval60;
    _displayLink = nil;
    [self doHavePrimePower];
    
    glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!glContext || ![EAGLContext setCurrentContext:glContext]) {
        return NO;
    }
    
    return YES;
}

- (void)doHavePrimePower {
    isPrimePower = YES;
}

- (BOOL)doInitRenderer {
    renderer = [[GLImageRenderer alloc] initWithContext:glContext AndDrawable:(id<EAGLDrawable>)self.layer];
    if (!renderer) {
        return NO;
    }
    
    return YES;
}

- (void)dealloc {
    [self stopAnimation];
    if ([EAGLContext currentContext] == glContext) {
        [EAGLContext setCurrentContext:nil];
    }
    glContext = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (renderer) {
        [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
}

- (void)doDrawing {
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
        [renderer render];
    }
    
    if (oldContext != glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
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

- (GLRenderFrameInterval)renderFrameInterval {
    return _renderFrameInterval;
}

- (void)setRenderFrameInterval:(GLRenderFrameInterval)renderFrameInterval {
    NSAssert(renderFrameInterval > GLRenderFrameIntervalUnknown, @"Render inverval zero is undefine");
    
    _renderFrameInterval = renderFrameInterval;
    if (isPrimePower) {
        //如果当前正在运行,则需要停止当前循环并更新帧间隔再开启
        if (_displayLink) {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation {
    if (isPrimePower && !_displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(doDrawing)];
        [self.displayLink setFrameInterval:_renderFrameInterval];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    } else {
        NSLog(@"can not start prime power = %d", isPrimePower);
    }
}

- (void)stopAnimation {
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

@end
