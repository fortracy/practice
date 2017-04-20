//
//  GLPixelRenderCopy.h
//  practicework
//
//  Created by bleach on 16/6/5.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface GLPixelRenderCopy : NSObject

- (id)initWithSize:(CGSize)framebufferSize;
- (BOOL)generateCopyFramebuffer;
- (void)deleteBuffers;
- (CVPixelBufferRef)copyRenderedPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CMFormatDescriptionRef)outputFormatDescription;

@end
