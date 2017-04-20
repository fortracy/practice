//
//  GLPixelRenderCopy.m
//  practicework
//
//  Created by bleach on 16/6/5.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLPixelRenderCopy.h"
#import "GLTools.h"
#import "GLBaseFilter.h"

#define RENDER_RETAINED_BUFFER_COUNT 10

@interface GLPixelRenderCopy()

@property (nonatomic, strong) GLBaseFilter* filter;

@end

@implementation GLPixelRenderCopy {
    EAGLContext* m_glContext;
    CVOpenGLESTextureCacheRef m_textureCache;
    CVOpenGLESTextureCacheRef m_renderTextureCache;
    CVPixelBufferPoolRef m_bufferPool;
    CFDictionaryRef m_bufferPoolAuxAttributes;
    GLuint m_offscreenFrameBuffer;
    CGSize m_srcSize;
    CGSize m_dstSize;
    GLTextureOptions m_textureOptions;
    CMFormatDescriptionRef m_outputFormatDescription;
    
    GLfloat* vertices;
    GLfloat* textureCoordinates;
    GLsizei pointCount;
    GLsizei copyFrameWidth;
    GLsizei copyFrameHeight;
}

- (id)initWithSize:(CGSize)framebufferSize {
    GLTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    defaultTextureOptions.mimap = GL_FALSE;
    
    if (!(self = [self initWithSize:framebufferSize textureOptions:defaultTextureOptions])) {
        return nil;
    }
    
    return self;
}

- (id)initWithSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)fboTextureOptions {
    if (!(self = [super init])) {
        return nil;
    }
    
    m_glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!m_glContext || ![EAGLContext setCurrentContext:m_glContext]) {
        return nil;
    }
    
    m_textureOptions = fboTextureOptions;
    m_srcSize = framebufferSize;
    m_dstSize = framebufferSize;
    
    [self doInitData];
    [self doInitFilter];

    BOOL result = [self generateCopyFramebuffer];
    if (!result) {
        NSAssert(NO, @"Can not support fast texture");
    }
    
    return self;
}

- (void)doInitFilter {
    _filter = [[GLBaseFilter alloc] initWithSize:m_srcSize];
}

- (void)doInitData {
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

#pragma mark - public
- (BOOL)generateCopyFramebuffer {
    if (![GLTools supportsFastTextureUpload]) {
        return NO;
    }
    BOOL success = YES;
    
    EAGLContext* oldContext = [EAGLContext currentContext];
    if (oldContext != m_glContext) {
        if (![EAGLContext setCurrentContext:m_glContext]) {
            NSLog(@"not current gl context");
            return NO;
        }
    }
    
    do {
        glDisable(GL_DEPTH_TEST);
        
        glGenFramebuffers(1, &m_offscreenFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, m_offscreenFrameBuffer);
        
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, m_glContext, NULL, &m_textureCache);
        if (err) {
            NSLog(@"error at CVOpenGLESTextureCacheCreate %d", err);
            success = NO;
            break;
        }
        
        err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, m_glContext, NULL, &m_renderTextureCache);
        if (err) {
            NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
            success = NO;
            break;
        }
        
        /* pixel buffer pool */
        size_t maxRetainedBufferCount = RENDER_RETAINED_BUFFER_COUNT;
        m_bufferPool = [GLTools createPixelBufferPool:m_srcSize.width height:m_srcSize.height pixelFormat:kCVPixelFormatType_32BGRA maxBufferCount:(int32_t)maxRetainedBufferCount];
        if (!m_bufferPool) {
            success = NO;
            break;
        }
        
        m_bufferPoolAuxAttributes = [GLTools createPixelBufferPoolAuxAttributes:(int32_t)maxRetainedBufferCount];
        [GLTools preallocatePixelBuffersInPool:m_bufferPool auxAttributes:m_bufferPoolAuxAttributes];
        
        /* test to get ouput format desc */
        CMFormatDescriptionRef outputFormatDescription = NULL;
        CVPixelBufferRef testPixelBuffer = NULL;
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, m_bufferPool, m_bufferPoolAuxAttributes, &testPixelBuffer);
        if (!testPixelBuffer) {
            success = NO;
            break;
        }
        CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, testPixelBuffer, &outputFormatDescription);
        m_outputFormatDescription = outputFormatDescription;
        CFRelease(testPixelBuffer);
    } while (false);
    
    if (!success) {
        [self deleteBuffers];
    }
    
    if (oldContext != m_glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
    
    return success;
}

- (void)deleteBuffers {
    EAGLContext* oldContext = [EAGLContext currentContext];
    if (oldContext != m_glContext) {
        if (![EAGLContext setCurrentContext:m_glContext]) {
            NSLog(@"not current gl context");
            return;
        }
    }
    
    if (m_offscreenFrameBuffer) {
        glDeleteFramebuffers(1, &m_offscreenFrameBuffer);
        m_offscreenFrameBuffer = 0;
    }
    if (m_textureCache) {
        CFRelease(m_textureCache);
        m_textureCache = 0;
    }
    if (m_renderTextureCache) {
        CFRelease(m_renderTextureCache);
        m_renderTextureCache = 0;
    }
    if (m_bufferPool) {
        CFRelease(m_bufferPool);
        m_bufferPool = NULL;
    }
    if (m_bufferPoolAuxAttributes) {
        CFRelease(m_bufferPoolAuxAttributes);
        m_bufferPoolAuxAttributes = NULL;
    }
    if (m_outputFormatDescription) {
        CFRelease(m_outputFormatDescription);
        m_outputFormatDescription = NULL;
    }
    
    if (oldContext != m_glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
}

- (CVPixelBufferRef)copyRenderedPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (m_offscreenFrameBuffer == 0) {
        NSLog(@"uninitialized buffer");
        return NULL;
    }
    
    if (pixelBuffer == NULL) {
        NSLog(@"pixelBuffer is nil");
        return NULL;
    }
    
    const CMVideoDimensions srcDimensions = {
        (int32_t)CVPixelBufferGetWidth(pixelBuffer),
        (int32_t)CVPixelBufferGetHeight(pixelBuffer)
    };
    
    /* format must same to inputPixelFormat */
    if (CVPixelBufferGetPixelFormatType(pixelBuffer) != kCVPixelFormatType_32BGRA) {
        NSLog(@"invalid pixel buffer format");
        return NULL;
    }
    
    EAGLContext* oldContext = [EAGLContext currentContext];
    if (oldContext != m_glContext) {
        if (![EAGLContext setCurrentContext:m_glContext]) {
            return NULL;
        }
    }
    
    CVReturn err = noErr;
    CVOpenGLESTextureRef srcTexture = NULL;
    CVOpenGLESTextureRef dstTexture = NULL;
    CVPixelBufferRef dstPixelBuffer = NULL;
    
    do {
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           m_textureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           srcDimensions.width,
                                                           srcDimensions.height,
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &srcTexture);
        if (!srcTexture || err) {
            NSLog(@"error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            break;
        }
        
        err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, m_bufferPool, m_bufferPoolAuxAttributes, &dstPixelBuffer);
        if (err == kCVReturnWouldExceedAllocationThreshold) {
            /* flush the texture cache and try again */
            CVOpenGLESTextureCacheFlush( m_renderTextureCache, 0 );
            err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, m_bufferPool, m_bufferPoolAuxAttributes, &dstPixelBuffer);
        }
        if (err) {
            if (err == kCVReturnWouldExceedAllocationThreshold) {
                NSLog(@"pool is out of buffers, dropping frame");
            } else {
                NSLog(@"error at CVPixelBufferPoolCreatePixelBuffer %d", err);
            }
            break;
        }
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           m_renderTextureCache,
                                                           dstPixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           m_dstSize.width,
                                                           m_dstSize.height,
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &dstTexture);
        
        if (!dstTexture || err) {
            NSLog(@"error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            break;
        }
        
        /* set viewport */
        glBindFramebuffer(GL_FRAMEBUFFER, m_offscreenFrameBuffer);
        glViewport(0, 0, m_dstSize.width, m_dstSize.height);
        
        glActiveTexture(GL_TEXTURE0);
        GLenum dstTextureTarget = CVOpenGLESTextureGetTarget(dstTexture);
        GLenum dstTextureId = CVOpenGLESTextureGetName(dstTexture);
        glBindTexture(dstTextureTarget, dstTextureId);
        
        /* set texture parameters */
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, m_textureOptions.minFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, m_textureOptions.magFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, m_textureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, m_textureOptions.wrapT);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, dstTextureTarget, dstTextureId, 0);
        
        /* draw something */
        glActiveTexture(GL_TEXTURE1);
        GLenum srcTextureTarget = CVOpenGLESTextureGetTarget(srcTexture);
        GLenum srcTextureId = CVOpenGLESTextureGetName(srcTexture);
        glBindTexture(srcTextureTarget, srcTextureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, m_textureOptions.minFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, m_textureOptions.magFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, m_textureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, m_textureOptions.wrapT);
        
        [self updateCopyCoordinates:srcDimensions];
        [self doRenderWithTexture:GL_TEXTURE1 - GL_TEXTURE0];
        
        glBindTexture(srcTextureTarget, 0);
        glBindTexture(dstTextureTarget, 0);
        
        glFlush();
    } while (false);
    
    if (oldContext != m_glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
    if (srcTexture) {
        CFRelease(srcTexture);
    }
    if (dstTexture) {
        CFRelease(dstTexture);
    }
    
    return dstPixelBuffer;
}

- (void)updateCopyCoordinates:(CMVideoDimensions)srcDimensions {
    GLsizei frameWidth = (GLsizei)srcDimensions.width;
    GLsizei frameHeight = (GLsizei)srcDimensions.height;
    if (copyFrameWidth != frameWidth || copyFrameHeight != frameHeight) {
        CGSize textureSamplingSize;
        CGSize cropScaleAmount = CGSizeMake(m_dstSize.width / (float)frameWidth, m_dstSize.height / (float)frameHeight);
        if (cropScaleAmount.height > cropScaleAmount.width) {
            textureSamplingSize.width = m_dstSize.width / (frameWidth * cropScaleAmount.height);
            textureSamplingSize.height = 1.0;
        } else {
            textureSamplingSize.width = 1.0;
            textureSamplingSize.height = m_dstSize.height / (frameHeight * cropScaleAmount.width);
        }
        
        /* CVPixelBuffers have a top left origin and OpenGL has a bottom left origin, swapping it */
        GLfloat passThroughTextureVertices[] = {
            (1.0 - textureSamplingSize.width) / 2.0, (1.0 + textureSamplingSize.height) / 2.0, // top left
            (1.0 + textureSamplingSize.width) / 2.0, (1.0 + textureSamplingSize.height) / 2.0, // top right
            (1.0 - textureSamplingSize.width) / 2.0, (1.0 - textureSamplingSize.height) / 2.0, // bottom left
            (1.0 + textureSamplingSize.width) / 2.0, (1.0 - textureSamplingSize.height) / 2.0, // bottom right
        };
        
        memcpy(textureCoordinates, passThroughTextureVertices, sizeof(GLfloat) * 8);
        
        copyFrameWidth = frameWidth;
        copyFrameHeight = frameHeight;
    }
}

- (CMFormatDescriptionRef)outputFormatDescription {
    return m_outputFormatDescription;
}

- (void)doRenderWithTexture:(GLuint)uniformId {
    if (_filter) {
        [_filter renderFrameNoBindWithVertices:vertices textureCoordinates:textureCoordinates pointCount:pointCount uniformId:uniformId];
    }
}

@end
