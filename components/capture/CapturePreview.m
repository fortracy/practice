//
//  CapturePreview.m
//  practicework
//
//  Created by bleach on 16/5/16.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "CapturePreview.h"
#import "GLTools.h"
#import "SVShaderUtilities.h"

typedef NS_ENUM(NSUInteger, SVPreviewAttributeType) {
    SVPreviewAttribute_Vertex,
    SVPreviewAttribute_TexturePosition,
    SVPreviewAttribute_Number
};

@interface CapturePreview ()

@property (nonatomic, strong) EAGLContext* glContext;
@property (nonatomic, strong) __attribute__((NSObject)) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic, assign) GLint bufferWidth;
@property (nonatomic, assign) GLint bufferHeight;
@property (nonatomic, assign) GLuint frameBufferHandle;
@property (nonatomic, assign) GLuint colorBufferHandle;
@property (nonatomic, assign) GLuint programId;
//@property (nonatomic, assign) GLuint

@end

@implementation CapturePreview {
    EAGLContext* m_glContext;
    CVOpenGLESTextureCacheRef m_textureCache;
    GLint m_width;
    GLint m_height;
    GLuint m_frameBufferHandle;
    GLuint m_colorBufferHandle;
    GLuint m_program;
    GLint m_frame;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ( [UIScreen instancesRespondToSelector:@selector(nativeScale)] ) {
            self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        }
        else
#endif
        {
            self.contentScaleFactor = [UIScreen mainScreen].scale;
        }
        
        CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking : @(NO),
                                          kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8 };
        
        m_glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!m_glContext) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [self reset];
    m_glContext = nil;
}

- (BOOL)initializeBuffers {
    BOOL success = YES;
    
    do {
        glDisable(GL_DEPTH_TEST);
        
        glGenFramebuffers(1, &m_frameBufferHandle);
        glBindFramebuffer(GL_FRAMEBUFFER, m_frameBufferHandle);
        
        glGenRenderbuffers(1, &m_colorBufferHandle);
        glBindRenderbuffer(GL_RENDERBUFFER, m_colorBufferHandle);
        
        [m_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &m_width);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &m_height);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_colorBufferHandle);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            success = NO;
            break;
        }
        
        CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, m_glContext, NULL, &m_textureCache );
        if (err) {
            success = NO;
            break;
        }
        
        GLint attribLocation[SVPreviewAttribute_Number] = {
            SVPreviewAttribute_Vertex, SVPreviewAttribute_TexturePosition,
        };
        GLchar* attribName[SVPreviewAttribute_Number] = {
            "position", "texturecoordinate",
        };
        
        const GLchar* vertSrc = [[GLTools readShaderFile:@"preview_vert.vsh"] UTF8String];
        const GLchar* fragSrc = [[GLTools readShaderFile:@"preview_frag.fsh"] UTF8String];
        
        glueCreateProgram(vertSrc, fragSrc, SVPreviewAttribute_Number, (const GLchar **)&attribName[0], attribLocation, 0, 0, 0, &m_program);
        
        if (!m_program) {
            success = NO;
            break;
        }
        
        m_frame = glueGetUniformLocation( m_program, "videoframe" );
    } while (false);
    
    if (!success) {
        [self reset];
    }
    return success;
}

- (void)reset {
    /* get current context */
    EAGLContext* oldContext = [EAGLContext currentContext];
    if (oldContext != m_glContext) {
        if (![EAGLContext setCurrentContext:m_glContext]) {
            return;
        }
    }
    
    if (m_frameBufferHandle) {
        glDeleteFramebuffers(1, &m_frameBufferHandle);
        m_frameBufferHandle = 0;
    }
    
    if (m_colorBufferHandle) {
        glDeleteRenderbuffers(1, &m_colorBufferHandle);
        m_colorBufferHandle = 0;
    }
    
    if (m_program) {
        glDeleteProgram(m_program);
        m_program = 0;
    }
    
    if (m_textureCache) {
        CFRelease(m_textureCache);
        m_textureCache = 0;
    }
    
    /* restore current context */
    if (oldContext != m_glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer isFrontCamera:(BOOL)isFrontCamera {
    /* make a squareVertics, because not use matrix ortho, set -1.0 ~ 1.0 */
    static const GLfloat squareVerticesNormal[] = {
        -1.0f, -1.0f, 1.0f, -1.0f, -1.0f, 1.0f, 1.0f, 1.0f,
    };
    static const GLfloat squareVerticesMirror[] = {
        -1.0f, 1.0f, 1.0f, 1.0f, -1.0f, -1.0f, 1.0f, -1.0f,
    };
    
    const GLfloat * squareVertices = squareVerticesNormal;
    
    if (pixelBuffer == NULL) {
        return;
    }
    
    
    /* bind gl context */
    EAGLContext* oldContext = [EAGLContext currentContext];
    if (oldContext != m_glContext) {
        if (![EAGLContext setCurrentContext:m_glContext]) {
            return;
        }
    }
    
    /* init frame buffer */
    if (m_frameBufferHandle == 0) {
        BOOL success = [self initializeBuffers];
        if (!success) {
            return;
        }
    }
    
    /* create texture */
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    CVOpenGLESTextureRef texture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                m_textureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                (GLsizei)frameWidth,
                                                                (GLsizei)frameHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture);
    
    
    if (!texture || err) {
        return;
    }
    
    /* set viewport */
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBufferHandle);
    glViewport(0, 0, m_width, m_height);
    
    /* bind shader, and bind texture with m_frame */
    glUseProgram(m_program);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));
    glUniform1i(m_frame, 0);
    
    /* set texture parameters */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glVertexAttribPointer(SVPreviewAttribute_Vertex, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(SVPreviewAttribute_Vertex);
    
    /* calculate aspect ratio */
    CGSize textureSamplingSize;
    CGSize cropScaleAmount = CGSizeMake(self.bounds.size.width / (float)frameWidth, self.bounds.size.height / (float)frameHeight);
    if (cropScaleAmount.height > cropScaleAmount.width) {
        textureSamplingSize.width = self.bounds.size.width / (frameWidth * cropScaleAmount.height);
        textureSamplingSize.height = 1.0;
    } else {
        textureSamplingSize.width = 1.0;
        textureSamplingSize.height = self.bounds.size.height / ( frameHeight * cropScaleAmount.width );
    }
    
    /* CVPixelBuffers have a top left origin and OpenGL has a bottom left origin, swapping it */
    GLfloat passThroughTextureVertices[] = {
        (1.0 - textureSamplingSize.width) / 2.0, (1.0 + textureSamplingSize.height) / 2.0, // top left
        (1.0 + textureSamplingSize.width) / 2.0, (1.0 + textureSamplingSize.height) / 2.0, // top right
        (1.0 - textureSamplingSize.width) / 2.0, (1.0 - textureSamplingSize.height) / 2.0, // bottom left
        (1.0 + textureSamplingSize.width) / 2.0, (1.0 - textureSamplingSize.height) / 2.0, // bottom right
    };
    
    glVertexAttribPointer(SVPreviewAttribute_TexturePosition, 2, GL_FLOAT, 0, 0, passThroughTextureVertices);
    glEnableVertexAttribArray(SVPreviewAttribute_TexturePosition);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbuffer(GL_RENDERBUFFER, m_colorBufferHandle);
    [m_glContext presentRenderbuffer:GL_RENDERBUFFER];
    
    glBindTexture(CVOpenGLESTextureGetTarget(texture), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    CFRelease(texture);
    
    if (oldContext != m_glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
}

- (void)flushPixelBufferCache {
    if (m_textureCache) {
        CVOpenGLESTextureCacheFlush(m_textureCache, 0);
    }
}


@end
