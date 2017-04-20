//
//  GLBaseFilter.m
//  practicework
//
//  Created by bleach on 16/5/25.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLBaseFilter.h"
#import "GLTools.h"
#import "GLMatrix.h"

NSString *const kBaseVertexShaderString = SHADER_STRING
(
    attribute vec4 aPosition;
    attribute vec4 aInputTextureCoordinate;
 
    varying vec2 vTextureCoordinate;
 
    uniform mat4 uModelViewProjMatrix;
 
    void main() {
        gl_Position =  aPosition;
        vTextureCoordinate = aInputTextureCoordinate.xy;
    }
);

NSString *const kBaseFragmentShaderString = SHADER_STRING
(
    precision mediump float;
    varying mediump vec2 vTextureCoordinate;
    uniform sampler2D uInputImageTexture;
 
    void main() {
        vec4 textureColor = texture2D(uInputImageTexture, vTextureCoordinate);
        gl_FragColor = textureColor;//vec4(textureColor.rgb * textureColor.w, textureColor.w);
    }
);

@implementation GLBaseFilter

- (id)initWithSize:(CGSize)viewSize {
    if (!(self = [self initWithFragmentShaderFromString:kBaseFragmentShaderString viewSize:viewSize])) {
        return nil;
    }
    
    return self;
}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString viewSize:(CGSize)viewSize {
    return [self initWithVertexShaderFromString:kBaseVertexShaderString fragmentShaderFromString:fragmentShaderString viewSize:viewSize];
}

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString viewSize:(CGSize)viewSize {
    if (!(self = [super init])) {
        return nil;
    }
    _bgColor.red = 0.0f;
    _bgColor.green = 0.0f;
    _bgColor.blue = 0.0f;
    _bgColor.alpha = 0.0f;
    _viewSize = viewSize;
    
    [self resetMatrix];
    [self doInit];
    
    baseFrameBuffer = [[GLFrameBuffer alloc] initWithSize:viewSize];
    baseProgram = [[GLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
    if (!baseProgram.initialized) {
        [self initializeAttributes];
        if (![baseProgram link]) {
            baseProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }
    
    [baseProgram use];
    filterPositionAttribute = [baseProgram attributeIndex:@"aPosition"];
    filterTextureCoordinateAttribute = [baseProgram attributeIndex:@"aInputTextureCoordinate"];
    filterModelViewProjMatrixUniform = [baseProgram uniformIndex:@"uModelViewProjMatrix"];
    filterInputTextureUniform = [baseProgram uniformIndex:@"uInputImageTexture"];
    
    GetGLError();
    
    return self;
}

- (void)doInit {
    baseTexture = [[GLTexture alloc] initNormalTexture:NO];
}

- (void)resetMatrix {
    if (!baseMatrix) {
        baseMatrix = [[GLMatrix alloc] init];
    } else {
        [baseMatrix setIdentity];
    }
    [baseMatrix setLookAt:0.0f eyeY:0.0f eyeZ:1.0f centerX:0.0f centerY:0.0f centerZ:0.0f upX:0.0f upY:1.0f upZ:0.0f];
    [baseMatrix orthographic:-1.0f right:1.0f bottom:-1.0f top:1.0f nearZ:-1.0f farZ:1.0f];
//    [baseMatrix orthographic:-_viewSize.width / 2.0f right:_viewSize.width / 2.0f bottom:-_viewSize.height / 2.0f top:_viewSize.height / 2.0f nearZ:-1.0f farZ:1.0f];
}

- (void)initializeAttributes {
    if (baseProgram) {
        [baseProgram addAttribute:@"aPosition"];
        [baseProgram addAttribute:@"aInputTextureCoordinate"];
        [self doinitializeAttributes];
    } else {
        NSAssert(NO, @"BaseProgram have not init");
    }
}

- (void)doinitializeAttributes {
    
}

- (void)updateViewSize:(CGSize)newViewSize {
    _viewSize = newViewSize;
    [self resetMatrix];
}

- (void)renderWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount {
    GLuint textureId = baseTexture.bindTexture;
    [self renderFrameWithVertices:vertices textureCoordinates:textureCoordinates pointCount:pointCount textureId:textureId];
}

- (void)renderElementWithPackBuffer:(const GLuint)packBuffer indexBuffer:(const GLuint)indexBuffer elementCount:(const GLsizei)elementCount needUpdate:(BOOL)needUpdate {
    GLuint textureId = baseTexture.bindTexture;
    [self renderElementFrameWithVertices:packBuffer indexBuffer:indexBuffer elementCount:elementCount textureId:textureId needUpdate:needUpdate];
}

- (void)renderOffscreenWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount {
    [baseFrameBuffer activateFramebuffer];
    [self renderWithVertices:vertices textureCoordinates:textureCoordinates pointCount:pointCount];
    [baseFrameBuffer deactiveFramebuffer];
}

- (void)renderOffscreenWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount textureId:(GLuint)textureId {
    [baseFrameBuffer activateFramebuffer];
    [self renderFrameWithVertices:vertices textureCoordinates:textureCoordinates pointCount:pointCount textureId:textureId];
    [baseFrameBuffer deactiveFramebuffer];
}

- (void)renderFrameWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount textureId:(GLuint)textureId {
    glViewport(0.0f, 0.0f, _viewSize.width, _viewSize.height);
    glClearColor(_bgColor.red, _bgColor.green, _bgColor.blue, _bgColor.alpha);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    if (baseProgram == nil) {
        NSLog(@"BaseProgram is nil");
        return;
    }
    [baseProgram use];

    [self doRenderPrepare];
    glUniformMatrix4fv(filterModelViewProjMatrixUniform, 1, GL_FALSE, baseMatrix.mtxElements);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(filterInputTextureUniform, 1);
    
    glVertexAttribPointer(filterPositionAttribute, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(filterPositionAttribute);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 0, textureCoordinates);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, pointCount);

    
    glDisableVertexAttribArray(filterPositionAttribute);
    glDisableVertexAttribArray(filterTextureCoordinateAttribute);
    GetGLError();
}

- (void)renderElementFrameWithVertices:(const GLuint)packBuffer indexBuffer:(const GLuint)indexBuffer elementCount:(const GLsizei)elementCount textureId:(GLuint)textureId needUpdate:(BOOL)needUpdate {
    glViewport(0.0f, 0.0f, _viewSize.width, _viewSize.height);
    glClearColor(_bgColor.red, _bgColor.green, _bgColor.blue, _bgColor.alpha);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    if (baseProgram == nil) {
        NSLog(@"BaseProgram is nil");
        return;
    }
    [baseProgram use];
    
    glUniformMatrix4fv(filterModelViewProjMatrixUniform, 1, GL_FALSE, baseMatrix.mtxElements);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(filterInputTextureUniform, 1);
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    [self doRenderPrepare];
    if (needUpdate) {
        glBindBuffer(GL_ARRAY_BUFFER, packBuffer);
        glVertexAttribPointer(filterPositionAttribute, 4, GL_FLOAT, GL_FALSE, sizeof(GLPackData), 0);
        glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(GLPackData), (const GLvoid *)(ptrdiff_t)(sizeof(GLVertex4)));
        [self doRenderBuffer];
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glDrawElements(GL_TRIANGLES, 6 * elementCount, GL_UNSIGNED_SHORT, (char *)0);
    
    glDisableVertexAttribArray(filterPositionAttribute);
    glDisableVertexAttribArray(filterTextureCoordinateAttribute);
    [self doRenderEnd];
    GetGLError();
}

- (void)renderFrameNoBindWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount uniformId:(GLint)uniformId {
    glViewport(0.0f, 0.0f, _viewSize.width, _viewSize.height);
    glClearColor(_bgColor.red, _bgColor.green, _bgColor.blue, _bgColor.alpha);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDisable(GL_BLEND);
    
    if (baseProgram == nil) {
        NSLog(@"BaseProgram is nil");
        return;
    }
    [baseProgram use];
    
    [self doRenderPrepare];
    glUniformMatrix4fv(filterModelViewProjMatrixUniform, 1, GL_FALSE, baseMatrix.mtxElements);
    
    glUniform1i(filterInputTextureUniform, uniformId);
    
    glVertexAttribPointer(filterPositionAttribute, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(filterPositionAttribute);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 0, textureCoordinates);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, pointCount);
    
    glDisableVertexAttribArray(filterPositionAttribute);
    glDisableVertexAttribArray(filterTextureCoordinateAttribute);
    GetGLError();
}

- (void)renderFromOffcreen {

}

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (baseTexture) {
        [baseTexture updateTextureWithPixelBuffer:pixelBuffer];
    }
}

- (void)updateTextureWithUIImage:(UIImage *)image {
    if (baseTexture) {
        [baseTexture updateTextureWithUIImage:image];
    }
}

- (void)updatePvrTextureWithName:(NSString *)pvrFilePath {
    if (baseTexture) {
        [baseTexture updatePvrTextureWithName:pvrFilePath];
    }
}

- (void)updateTextureWithImageData:(SImageData *)imageData {
    if (baseTexture) {
        [baseTexture updateTextureWithImageData:imageData];
    }
}

- (GLuint)frameBufferTexture {
    return baseFrameBuffer.bindTexture;
}

- (void)doRenderPrepare {
    
}

- (void)doRenderEnd {
    
}

- (void)doRenderBuffer {
    
}

#pragma mark - property
- (void)setFloat:(GLuint)location floatValue:(GLfloat)floatValue {
    glUniform1f(location, floatValue);
}

@end
