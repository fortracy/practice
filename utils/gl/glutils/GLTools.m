//
//  GLTools.m
//  practicework
//
//  Created by bleach on 16/5/15.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLTools.h"

@implementation GLTools

+ (NSString *)readShaderFile:(NSString *)shaderName {
    NSString* path = [[NSBundle mainBundle] pathForResource:shaderName ofType: nil];
    return [GLTools readShaderFileFromPath:path];
}

+ (NSString *)readShaderFileFromPath:(NSString *)shaderPath {
    return [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:nil];
}

+ (CVPixelBufferPoolRef)createPixelBufferPool:(int32_t)width height:(int32_t)height pixelFormat:(FourCharCode)pixelFormat maxBufferCount:(int32_t)maxBufferCount {
    CVPixelBufferPoolRef outputPool = NULL;
    
    NSDictionary* sourcePixelBufferOptions = @{
                                               (id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormat),
                                               (id)kCVPixelBufferWidthKey : @(width),
                                               (id)kCVPixelBufferHeightKey : @(height),
                                               (id)kCVPixelFormatOpenGLESCompatibility : @(YES),
                                               (id)kCVPixelBufferIOSurfacePropertiesKey : @{}
                                               };
    
    NSDictionary* pixelBufferPoolOptions = @{ (id)kCVPixelBufferPoolMinimumBufferCountKey : @(maxBufferCount) };
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault, (__bridge CFDictionaryRef)pixelBufferPoolOptions, (__bridge CFDictionaryRef)sourcePixelBufferOptions, &outputPool);
    
    return outputPool;
}

+ (CFDictionaryRef)createPixelBufferPoolAuxAttributes:(int32_t)maxBufferCount {
    /* CVPixelBufferPoolCreatePixelBufferWithAuxAttributes() will return kCVReturnWouldExceedAllocationThreshold if we have already vended the max number of buffers */
    return CFRetain((__bridge CFTypeRef)(@{ (id)kCVPixelBufferPoolAllocationThresholdKey : @(maxBufferCount) }));
}

+ (void)preallocatePixelBuffersInPool:(CVPixelBufferPoolRef)pool auxAttributes:(CFDictionaryRef)auxAttributes {
    /* preallocate buffers in the pool, since this is for real-time display/capture */
    NSMutableArray* pixelBuffers = [[NSMutableArray alloc] init];
    while (1) {
        CVPixelBufferRef pixelBuffer = NULL;
        OSStatus err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer);
        
        if (err == kCVReturnWouldExceedAllocationThreshold) {
            break;
        }
        assert(err == noErr);
        
        [pixelBuffers addObject:(__bridge id)pixelBuffer];
        CFRelease(pixelBuffer);
    }
}

+ (BOOL)supportsFastTextureUpload {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop
    
#endif
}

@end
