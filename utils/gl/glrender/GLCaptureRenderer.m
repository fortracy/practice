//
//  GLCaptureRenderer.m
//  practicework
//
//  Created by bleach on 16/5/31.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLCaptureRenderer.h"
#import "GLCaptureFilter.h"

@interface GLCaptureRenderer()

@property (nonatomic, strong) GLCaptureFilter* filter;

@end

@implementation GLCaptureRenderer {
    GLfloat* vertices;
    GLfloat* textureCoordinates;
    GLsizei pointCount;
    GLsizei captureFrameWidth;
    GLsizei captureFrameHeight;
}

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable {
    id obj = [super initWithContext:glContext AndDrawable:drawable];
    [self initData];
    return obj;
}

- (void)initData {
    captureFrameWidth = 0;
    captureFrameHeight = 0;
    
    if (!_filter) {
        _filter = [[GLCaptureFilter alloc] initWithSize:CGSizeMake(viewWidth, viewHeight)];
    }
    
    vertices = (GLfloat *)malloc(sizeof(GLfloat) * 12);
    textureCoordinates = (GLfloat *)malloc(sizeof(GLfloat) * 8);
    
    GLfloat squareVerticesNormal[] = {
        -1.f, -1.f, 0.0f,
        1.f, -1.f, 0.0f,
        -1.f, 1.f, 0.0f,
        1.f, 1.f, 0.0f
    };
    memcpy(vertices, squareVerticesNormal, sizeof(GLfloat) * 12);
    
    GLfloat squareTextureCoordinatesNormal[] =  {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    memcpy(textureCoordinates, squareTextureCoordinatesNormal, sizeof(GLfloat) * 8);
    
    pointCount = 4;
}

- (void)doRenderWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (pixelBuffer) {
        GLsizei frameWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
        GLsizei frameHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
        if (captureFrameWidth != frameWidth || captureFrameHeight != frameHeight) {
            CGSize textureSamplingSize;
            CGSize cropScaleAmount = CGSizeMake(viewWidth / (float)frameWidth, viewHeight / (float)frameHeight);
            if (cropScaleAmount.height > cropScaleAmount.width) {
                textureSamplingSize.width = viewWidth / (frameWidth * cropScaleAmount.height);
                textureSamplingSize.height = 1.0;
            } else {
                textureSamplingSize.width = 1.0;
                textureSamplingSize.height = viewHeight / (frameHeight * cropScaleAmount.width);
            }
            
            /* CVPixelBuffers have a top left origin and OpenGL has a bottom left origin, swapping it */
            GLfloat passThroughTextureVertices[] = {
                (1.0 - textureSamplingSize.width) / 2.0, (1.0 + textureSamplingSize.height) / 2.0, // top left
                (1.0 + textureSamplingSize.width) / 2.0, (1.0 + textureSamplingSize.height) / 2.0, // top right
                (1.0 - textureSamplingSize.width) / 2.0, (1.0 - textureSamplingSize.height) / 2.0, // bottom left
                (1.0 + textureSamplingSize.width) / 2.0, (1.0 - textureSamplingSize.height) / 2.0, // bottom right
            };
            
            memcpy(textureCoordinates, passThroughTextureVertices, sizeof(GLfloat) * 8);
            
            captureFrameWidth = frameWidth;
            captureFrameHeight = frameHeight;
        }
    }
    if (_filter) {
        [_filter updateTextureWithPixelBuffer:pixelBuffer];
        [_filter renderWithVertices:vertices textureCoordinates:textureCoordinates pointCount:pointCount];
        GetGLError();
    }
}

@end
