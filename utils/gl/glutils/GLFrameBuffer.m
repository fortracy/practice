//
//  GLFrameBuffer.m
//  practicework
//
//  Created by bleach on 16/5/25.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLFrameBuffer.h"
#import "GLTools.h"

@interface GLFrameBuffer()

//FrameBuffer的尺寸
@property (nonatomic, assign) CGSize size;
//纹理配置
@property (nonatomic, assign) GLTextureOptions textureOptions;
//申请的FrameBuffer Id
@property (nonatomic, assign) GLuint framebuffer;
//申请的RenderBuffer Id
@property (nonatomic, assign) GLuint depthBuffer;
//渲染的目标对象(能直接转换成图像)
@property (nonatomic, retain) __attribute__((NSObject)) CVPixelBufferRef renderTarget;
//渲染的目标对象纹理(可用于二次渲染)
@property (nonatomic, retain) __attribute__((NSObject)) CVOpenGLESTextureRef renderTexture;
//纹理缓存
@property (nonatomic, retain) __attribute__((NSObject)) CVOpenGLESTextureCacheRef textureCache;

@end

@implementation GLFrameBuffer {
    SImageData* imageData;
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
    
    _textureOptions = fboTextureOptions;
    _size = framebufferSize;
    imageData = NULL;
    
    [self generateFramebuffer];
    [self doRegisterNotification];
    return self;
}

- (id)initWithSize:(CGSize)framebufferSize inputTexture:(GLuint)inputTexture {
    if (!(self = [super init])) {
        return nil;
    }
    
    GLTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    defaultTextureOptions.mimap = GL_FALSE;

    _textureOptions = defaultTextureOptions;
    _size = framebufferSize;
    
    _bindTexture = inputTexture;
    imageData = NULL;
    
    return self;
}

- (void)activateFramebuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    glActiveTexture( GL_TEXTURE1 );
    glBindTexture( CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget( _renderTexture ), CVOpenGLESTextureGetName( _renderTexture ), 0 );
}

- (void)deactiveFramebuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

#pragma mark - inner
- (void)doRegisterNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)handleMemoryWarning {
    if (_textureCache) {
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
    }
}

- (void)generateTexture {
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_bindTexture);
    glBindTexture(GL_TEXTURE_2D, _bindTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
    if (_textureOptions.mimap) {
        glGenerateMipmap(GL_TEXTURE_2D);
    }
}

- (void)generateFramebuffer {
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    // create a depth buffer and bind it.
    glGenRenderbuffers(1, &_depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
    
    //是否可使用iOS的FBO加速(如果不可以就需要使用传统的glTexImage2D)
    if ([GLTools supportsFastTextureUpload]) {
        EAGLContext* glContext = [EAGLContext currentContext];
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, glContext, NULL, &_textureCache);
        if (err) {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
        
        CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
        err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_size.width, (int)_size.height, kCVPixelFormatType_32BGRA, attrs, &_renderTarget);
        if (err) {
            NSLog(@"FBO size: %f, %f", _size.width, _size.height);
            NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
        }
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                            _textureCache,
                                                            _renderTarget,
                                                            NULL,
                                                            GL_TEXTURE_2D,
                                                            _textureOptions.internalFormat,
                                                            (int)_size.width,
                                                            (int)_size.height,
                                                            _textureOptions.format,
                                                            _textureOptions.type,
                                                            0,
                                                            &_renderTexture);
        if (err) {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        CFRelease(attrs);
        CFRelease(empty);
        
        glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
        _bindTexture = CVOpenGLESTextureGetName(_renderTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _size.width, _size.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_renderTexture), 0);
    } else {
        [self generateTexture];
        glBindTexture(GL_TEXTURE_2D, _bindTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, _textureOptions.internalFormat, (int)_size.width, (int)_size.height, 0, _textureOptions.format, _textureOptions.type, 0);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _size.width, _size.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _bindTexture, 0);
    }
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)deinit {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_depthBuffer) {
        glDeleteRenderbuffers(1, &_depthBuffer);
        _depthBuffer = 0;
    }
    
    if ([GLTools supportsFastTextureUpload]) {
        //如果使用加速的纹理,不需要glDeleteTextures
        if (_renderTarget) {
            CFRelease(_renderTarget);
            _renderTarget = NULL;
        }
        
        if (_renderTexture) {
            CFRelease(_renderTexture);
            _renderTexture = NULL;
        }
        
        if (_textureCache) {
            CFRelease(_textureCache);
            _textureCache = NULL;
        }
    } else {
        glDeleteTextures(1, &_bindTexture);
        _bindTexture = 0;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self deinit];
}

@end
