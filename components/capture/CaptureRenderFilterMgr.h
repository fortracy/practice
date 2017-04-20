//
//  CaptureRenderFilterMgr.h
//  practicework
//
//  Created by bleach on 16/5/15.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface CaptureRenderFilterMgr : NSObject

@property (nonatomic, readonly) __attribute__((NSObject)) CMFormatDescriptionRef outputFormatDescription;
@property (nonatomic, readonly) BOOL operatesInPlace;
@property (nonatomic, readonly) FourCharCode inputPixelFormat;

/* 初始化滤镜处理所需要的东西 */
- (void)prepareForInputWithOutputDimensions:(CMVideoDimensions)outputDimensions;
- (CVPixelBufferRef)copyRenderedPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)reset;

@end
