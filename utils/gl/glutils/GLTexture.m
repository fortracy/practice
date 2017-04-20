  //
//  GLTexture.m
//  practicework
//
//  Created by bleach on 16/5/31.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLTexture.h"
#import "GLTools.h"
#import "PvrTextureInfo.h"

@interface GLTexture()
//纹理设置
@property (nonatomic, assign) GLTextureOptions textureOptions;
//是否强制不使用fastTexture
@property (nonatomic, assign) BOOL normalTexture;
//用于纹理
@property (nonatomic, assign) CGSize textureSize;
//纹理缓存
@property (nonatomic, retain) __attribute__((NSObject)) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic, retain) __attribute__((NSObject)) CVOpenGLESTextureRef renderTexture;
//
@property (nonatomic, strong) PvrTextureInfo* pvrInfo;

@end

@implementation GLTexture {
    SImageData* imageData;
}

- (id)initNormalTexture:(BOOL)normalTexture {
    GLTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    defaultTextureOptions.mimap = GL_FALSE;
    
    if (!(self = [self initWithOptions:defaultTextureOptions normalTexture:normalTexture])) {
        return nil;
    }
    
    return self;
}

- (id)initWithOptions:(GLTextureOptions)fboTextureOptions normalTexture:(BOOL)normalTexture {
    if (!(self = [super init])) {
        return nil;
    }
    
    _textureOptions = fboTextureOptions;
    _normalTexture = normalTexture;

    if ([GLTools supportsFastTextureUpload] && !normalTexture) {
        [self generateFastTexture];
    } else {
        [self generateTexture];
    }
    return self;
}

- (void)generateTexture {
    glActiveTexture(GL_TEXTURE0);
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

- (void)generateFastTexture {
    do {
        EAGLContext* glContext = [EAGLContext currentContext];
        CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, glContext, NULL, &_textureCache );
        if (err) {
            NSLog(@"GenerateFastTexture cache error!");
            break;
        }
        return;
    } while (false);
    
    [self deinit];
}

- (void)deinit {
    if ([GLTools supportsFastTextureUpload] && !_normalTexture) {
        if (_textureCache) {
            CFRelease(_textureCache);
            _textureCache = NULL;
        }
        if (_renderTexture != NULL) {
            CFRelease(_renderTexture);
            _renderTexture = NULL;
        }
    } else {
        glDeleteTextures(1, &_bindTexture);
        _bindTexture = 0;
    }
    
    if (imageData != NULL) {
        destroyImageData(imageData);
        imageData = NULL;
    }
}

- (GLuint)bindTexture {
    return _bindTexture;
}

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer || _normalTexture) {
        NSLog(@"Error updateTextureWithPixelBuffer");
        return;
    }

    //必须确保输入的pixel格式一致,否则无法绑定
    if (CVPixelBufferGetPixelFormatType(pixelBuffer) != kCVPixelFormatType_32BGRA) {
        NSLog(@"Invalid pixel buffer format");
        return;
    }
    
    if (![GLTools supportsFastTextureUpload]) {
        return;
    }
    
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    CVReturn err = noErr;
    CVOpenGLESTextureRef srcTexture = NULL;
    
    do {
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _textureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           (GLsizei)frameWidth,
                                                           (GLsizei)frameHeight,
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &srcTexture);
        if (!srcTexture || err) {
            NSLog(@"error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            break;
        }
        
        if (_renderTexture != NULL) {
            CFRelease(_renderTexture);
            _renderTexture = NULL;
        }
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(srcTexture), CVOpenGLESTextureGetName(srcTexture));
        
        /* set texture parameters */
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
        
        _bindTexture = CVOpenGLESTextureGetName(srcTexture);
        _renderTexture = srcTexture;
        _textureSize = CGSizeMake(frameWidth, frameHeight);
    } while (false);
}

- (void)updateTextureWithUIImage:(UIImage *)image {
    if (!_normalTexture) {
        NSLog(@"Error updateTextureWithUIImage");
        return;
    }
    if (imageData != NULL) {
        destroyImageData(imageData);
        imageData = NULL;
    }
    
    imageData = imageDataFromUIImage(image, YES);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _bindTexture);
    if (_textureSize.width != imageData->width || _textureSize.height != imageData->height) {
        glTexImage2D(GL_TEXTURE_2D, 0, imageData->format, (GLint)imageData->width, (GLint)imageData->height, 0, imageData->format, imageData->type, imageData->data);
        _textureSize.width = imageData->width;
        _textureSize.height = imageData->height;
    } else {
    //    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLint)imageData->width, (GLint)imageData->height, imageData->format, imageData->type, imageData->data);
    }
}

- (void)updatePvrTextureWithName:(NSString *)pvrFilePath {
    _pvrInfo = [PvrTextureInfo pvrTextureWithContentsOfFile:pvrFilePath];
    if (_pvrInfo == nil) {
        return;
    }
    
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _bindTexture);
    
    GLsizei width = _pvrInfo.width;
    GLsizei height = _pvrInfo.height;
    NSData* data = nil;
    GLenum err = GL_NO_ERROR;
    if(_pvrInfo.imageDatas.count == 1) {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    } else {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
    }
    
    for (int i = 0; i < _pvrInfo.imageDatas.count; i++) {
        data = [_pvrInfo.imageDatas objectAtIndex:i];
        
        if (_pvrInfo.compressed) {
            glCompressedTexImage2D(GL_TEXTURE_2D, i, _pvrInfo.internalFormat, width, height, 0, (GLsizei)[data length], [data bytes]);
        } else {
            glTexImage2D(GL_TEXTURE_2D, 0, _pvrInfo.internalFormat, width, height, 0, _pvrInfo.format, _pvrInfo.type, [data bytes]);
        }
        
        err = glGetError();
        if (err != GL_NO_ERROR) {
            NSLog(@"Error uploading compressed texture level: %d. glError: 0x%04X", i, err);
            return;
        }
        
        width = MAX(width >> 1, 1);
        height = MAX(height >> 1, 1);
    }
}

- (void)updateTextureWithImageData:(SImageData *)cacheImageData {
    if (!_normalTexture) {
        NSLog(@"Error updateTextureWithUIImage");
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _bindTexture);
    if (_textureSize.width != cacheImageData->width || _textureSize.height != cacheImageData->height) {
        glTexImage2D(GL_TEXTURE_2D, 0, cacheImageData->format, (GLint)cacheImageData->width, (GLint)cacheImageData->height, 0, cacheImageData->format, cacheImageData->type, cacheImageData->data);
        _textureSize.width = cacheImageData->width;
        _textureSize.height = cacheImageData->height;
    } else {
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLint)cacheImageData->width, (GLint)cacheImageData->height, cacheImageData->format, cacheImageData->type, cacheImageData->data);
    }
}

@end
