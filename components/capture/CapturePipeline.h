//
//  CapturePipeline.h
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class CapturePipeline;
@protocol CapturePipelineDelegate <NSObject>
@required
//failed event
- (void)capturePipeline:(CapturePipeline*)capturePipeline didStopRunningWithError:(NSError*)error;
//preview event
- (void)capturePipeline:(CapturePipeline*)capturePipeline previewPixelBufferReadyForDisplay:(CVPixelBufferRef)previewPixelBuffer;
- (void)capturePipelineDidRunOutOfPreviewBuffers:(CapturePipeline*)capturePipeline;

@end

@interface CapturePipeline : NSObject

@property (nonatomic, weak) id<CapturePipelineDelegate> capturePipelineDelegate;

/**
 * @brief 开启捕获(同步方法)
 * @param position : 默认打开的是前置摄像头还是后置摄像头
 */
- (void)startRunning:(AVCaptureDevicePosition)position;

/**
 * @brief 关闭捕获(同步方法)
 */
- (void)stopRunning;

/**
 * @brief 设置旋转,摄像头采集会旋转
 */
- (CGAffineTransform)transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)orientation withAutoMirroring:(BOOL)mirror;

@end
