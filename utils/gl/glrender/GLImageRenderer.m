//
//  GLImageRenderer.m
//  practicework
//
//  Created by bleach on 16/5/29.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLImageRenderer.h"
#import "GLImageFilter.h"
#import "GLGrayFilter.h"
#import "GLSaturationFilter.h"

@interface GLImageRenderer()

@property (nonatomic, strong) GLImageFilter* filter;

@end

@implementation GLImageRenderer {
    GLfloat* vertices;
    GLfloat* textureCoordinates;
    GLsizei pointCount;
}

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable {
    id obj = [super initWithContext:glContext AndDrawable:drawable];
    [self initData];
    return obj;
}

- (void)initData {
    if (!_filter) {
        _filter = [[GLImageFilter alloc] initWithSize:CGSizeMake(viewWidth, viewHeight)];
    }
    
//    DoCostTime([_filter updateTextureWithUIImage:[UIImage imageNamed:@"demon"]], @"Load Image ");

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

- (void)doRender {
    static GLuint index = 0;
    static GLuint parseCount = 0;

    if (_filter) {
        NSString* imageName = [NSString stringWithFormat:@"carnation_%d", index];
        [_filter updatePvrTextureWithName:[[NSBundle mainBundle] pathForResource:imageName ofType:@"pvr"]];
     //   [_filter updateTextureWithUIImage:[UIImage imageNamed:imageName]];
   //     [_filter updateTextureWithUIImage:[UIImage imageNamed:@"item_powerup_fish"]];
        [_filter renderWithVertices:vertices textureCoordinates:textureCoordinates pointCount:pointCount];
    }
    index++;
    if (index > 79) {
        index = 0;
        parseCount = 0;
    }
}

- (void)doRenderTexture:(GLuint)textureId {
    if (_filter) {
        [_filter renderFrameWithVertices:vertices textureCoordinates:textureCoordinates pointCount:pointCount textureId:textureId];
    }
}

@end
