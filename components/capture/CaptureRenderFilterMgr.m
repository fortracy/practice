//
//  CaptureRenderFilterMgr.m
//  practicework
//
//  Created by bleach on 16/5/15.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "CaptureRenderFilterMgr.h"
#import "GLTools.h"
#import "GLPixelRenderCopy.h"

#define RENDER_RETAINED_BUFFER_COUNT 6

@interface CaptureRenderFilterMgr() {

}

@property (nonatomic, strong) GLPixelRenderCopy* renderCopy;
@property (nonatomic, assign) CMVideoDimensions dstDimensions;
@property (nonatomic, retain) __attribute__((NSObject)) CVPixelBufferPoolRef bufferPool;
@property (nonatomic, retain) __attribute__((NSObject)) CFDictionaryRef bufferPoolAuxAttributes;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputFormatDescription;

@end

@implementation CaptureRenderFilterMgr

- (instancetype)init {
    self = [super init];
    return self;
}

#pragma --mark public 
- (void)prepareForInputWithOutputDimensions:(CMVideoDimensions)outputDimensions {
    if (!_renderCopy) {
        _renderCopy = [[GLPixelRenderCopy alloc] initWithSize:CGSizeMake(outputDimensions.width, outputDimensions.height)];
    } else {
        [_renderCopy deleteBuffers];
        if (![_renderCopy generateCopyFramebuffer]) {
            NSLog(@"GenerateCopyFramebuffer error");
        }
    }
}

- (CVPixelBufferRef)copyRenderedPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (_renderCopy) {
        return [_renderCopy copyRenderedPixelBuffer:pixelBuffer];
    } else {
        return nil;
    }
}

- (void)reset {
    [_renderCopy deleteBuffers];
}

#pragma mark render property
- (CMFormatDescriptionRef)outputFormatDescription {
    return [_renderCopy outputFormatDescription];
}

- (BOOL)operatesInPlace {
    return NO;
}

- (FourCharCode)inputPixelFormat {
    //avcaptureoutput supported pixel format:420v, 420f, BGRA
    return kCVPixelFormatType_32BGRA;
}

@end
