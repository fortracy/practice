//
//  GLBaseRenderer.m
//  practicework
//
//  Created by bleach on 16/5/20.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLBaseRenderer.h"

@interface GLBaseRenderer()

@property (nonatomic, weak) EAGLContext* glContext;
@property (nonatomic, assign) GLuint framebuffer;
@property (nonatomic, assign) GLuint colorRenderbuffer;
@property (nonatomic, assign) GLuint depthRenderbuffer;

@property (nonatomic, assign) GLuint targetFramebuffer;
@property (nonatomic, assign) GLuint targetDepthRenderbuffer;

@property (nonatomic, assign) GLuint massFrameramebuffer;
@property (nonatomic, assign) GLuint massColorRenderbuffer;
@property (nonatomic, assign) GLuint massDepthRenderbuffer;
@property (nonatomic, assign) GLuint massTextureId;

@end

@implementation GLBaseRenderer

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable {
    _glContext = glContext;
    
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    // 设置渲染缓冲区
    glGenRenderbuffers(1, &_colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);

    // 获取视图的尺寸
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &viewWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &viewHeight);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    GetGLError();
    
//    glGenRenderbuffers(1, &_depthRenderbuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
//    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, viewWidth, viewHeight);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    GetGLError();

    {
        glGenFramebuffers(1, &_targetFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _targetFramebuffer);
        GetGLError();

        glGenRenderbuffers(1, &_targetDepthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _targetDepthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, viewWidth, viewHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _targetDepthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        GetGLError();

        glGenTextures(1, &_massTextureId);
        glBindTexture(GL_TEXTURE_2D, _massTextureId);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, viewWidth, viewHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _massTextureId, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
        GetGLError();
    }

    {
        glGenFramebuffers(1, &_massFrameramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _massFrameramebuffer);
        GetGLError();

        glGenRenderbuffers(1, &_massColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _massColorRenderbuffer);
        glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_RGBA8, viewWidth, viewHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _massColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        GetGLError();
        
        // 设置深度缓冲区
//        glGenRenderbuffers(1, &_massDepthRenderbuffer);
//        glBindRenderbuffer(GL_RENDERBUFFER, _massDepthRenderbuffer);
//        glRenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, viewWidth, viewHeight);
//        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _massDepthRenderbuffer);
//        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        GetGLError();
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _massFrameramebuffer);
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return nil;
    }
    
    glViewport(0, 0, viewWidth, viewHeight);

    return self;
}

- (void)render {
    glBindFramebuffer(GL_FRAMEBUFFER, _massFrameramebuffer);
    
    // draw something
    [self doRender];

    glBindFramebuffer(GL_READ_FRAMEBUFFER, _massFrameramebuffer);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _targetFramebuffer);
    glBlitFramebuffer(0, 0, viewWidth, viewHeight, 0, 0, viewWidth, viewHeight, GL_COLOR_BUFFER_BIT, GL_LINEAR);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    [self doRenderTexture:_massTextureId];

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)renderWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    // draw something
    [self doRenderWithPixelBuffer:pixelBuffer];
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderOffscreenWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self doRenderWithPixelBuffer:pixelBuffer];
}

- (void)renderOffsreenToScreen {
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    // draw something
    [self renderFromOffcreen];
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderFromOffcreen {
    
}

- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer {
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &viewWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &viewHeight);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, viewWidth, viewHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
    
    glViewport(0, 0, viewWidth, viewHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    return YES;
}

#pragma --mark should overwrite
- (void)doRender {
}

- (void)doRenderTexture:(GLuint)textureId {
}

- (void)doRenderWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}

- (void)deinit {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_colorRenderbuffer) {
        glDeleteRenderbuffers(1, &_colorRenderbuffer);
        _colorRenderbuffer = 0;
    }
    
    if (_depthRenderbuffer) {
        glDeleteRenderbuffers(1, &_depthRenderbuffer);
        _depthRenderbuffer = 0;
    }
}

- (void)dealloc {
    [self deinit];
}

@end
