//
//  GLBaseRenderer.h
//  practicework
//
//  Created by bleach on 16/5/20.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

//每一个需要画出自己想要的图像的,继承这个类吧,然后定制自己的数据
@interface GLBaseRenderer : NSObject {
    GLint viewWidth;
    GLint viewHeight;
}

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable;

- (void)render;

- (void)renderWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)renderOffscreenWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)renderOffsreenToScreen;

- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer;

// should overwrite
- (void)doRender;

- (void)doRenderTexture:(GLuint)textureId;

- (void)renderFromOffcreen;

- (void)deinit;

@end
