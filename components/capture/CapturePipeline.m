//
//  CapturePipeline.m
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "CapturePipeline.h"
#import "CaptureRenderFilterMgr.h"

@interface CapturePipeline()<AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

//用于计算帧率
@property (nonatomic, strong) NSMutableArray* previousSecondTimestamps;
@property (nonatomic, assign) CGFloat videoFps;
//指定的回调线程
@property (nonatomic, strong) dispatch_queue_t delegateCallbackQueue;
//视频会话线程
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
//视频输出绘制线程(使用较高的线程优先级)
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
//音频输出线程(音频使用默认线程优先级)
@property (nonatomic, strong) dispatch_queue_t audioDataOutputQueue;
//申请后台任务(进入后台后,还能运行后台任务大概3分钟)
@property (nonatomic) UIBackgroundTaskIdentifier pipelineRunningTask;
//当前帧数据
@property (nonatomic, retain) __attribute__((NSObject)) CVPixelBufferRef currentPreviewPixelBuffer;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;
//当前是否正在运行
@property (nonatomic, assign) BOOL isRunning;
//是否在运行中退到后台
@property (nonatomic, assign) BOOL startCaptureSessionOnEnteringForeground;
//捕获会话(包括音视频)
@property (nonatomic, strong) AVCaptureSession* captureSession;
@property (nonatomic, strong) AVCaptureDevice* videoDevice;
@property (nonatomic, strong) AVCaptureDevice* audioDevice;
@property (nonatomic, strong) AVCaptureConnection* audioConnection;
@property (nonatomic, strong) AVCaptureConnection* videoConnection;
//捕获的参数设置
@property (nonatomic, strong) NSDictionary* videoCompressionSettings;
@property (nonatomic, strong) NSDictionary* audioCompressionSettings;
//视频的横屏还是竖屏
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;
//当前摄像头是前置还是后置
@property (nonatomic, assign) AVCaptureDevicePosition devidePosition;
//视频宽高
@property (nonatomic, assign) CMVideoDimensions videoDimensions;
//是否可渲染(若切换到后台,GPU可不用)
@property (nonatomic, assign) BOOL renderingEnabled;
//渲染管理器
@property (nonatomic, strong) CaptureRenderFilterMgr* renderMgr;

@end

@implementation CapturePipeline

- (instancetype)init {
    self = [super init];
    if (self) {
        _previousSecondTimestamps = [[NSMutableArray alloc] init];
        _sessionQueue = dispatch_queue_create("com.xlb.camerapipeline.session", DISPATCH_QUEUE_SERIAL);
        _videoDataOutputQueue = dispatch_queue_create("com.xlb.camerapipeline.video", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_videoDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _audioDataOutputQueue = dispatch_queue_create("com.xlb.camerapipeline.audio", DISPATCH_QUEUE_SERIAL);
        _delegateCallbackQueue = dispatch_get_main_queue();
        _pipelineRunningTask = UIBackgroundTaskInvalid;
        _renderingEnabled = YES;
        _renderMgr = [[CaptureRenderFilterMgr alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_previousSecondTimestamps removeAllObjects];
    _previousSecondTimestamps = nil;
    
    if (_currentPreviewPixelBuffer != nil) {
        CFRelease(_currentPreviewPixelBuffer);
    }
}

#pragma mark - session
- (void)startRunning:(AVCaptureDevicePosition)position {
    if (_isRunning) {
        return;
    }
    WeakSelf()
    dispatch_sync(_sessionQueue, ^{
        [weakSelf setupCaptureSession:position];
        [weakSelf.captureSession startRunning];
        weakSelf.isRunning = YES;
    });
}

- (void)stopRunning {
    if (!_isRunning) {
        return;
    }
    WeakSelf()
    dispatch_sync(_sessionQueue, ^{
        weakSelf.isRunning = NO;
        [weakSelf.captureSession stopRunning];
        [weakSelf captureSessionDidStopRunning];
        [weakSelf teardownCaptureSession];
    });
}

- (void)setupCaptureSession:(AVCaptureDevicePosition)position {
    if (_captureSession) {
        return;
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    
    /* add capture sesstion notification */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionNotification:) name:nil object:_captureSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureWillEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    /* audio collector */
    AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioDevice = audioDevice;
    AVCaptureDeviceInput* audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
    if ( [_captureSession canAddInput:audioInput] ) {
        [_captureSession addInput:audioInput];
    }
    
    AVCaptureAudioDataOutput* audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:_audioDataOutputQueue];
    if ([_captureSession canAddOutput:audioOutput] ) {
        [_captureSession addOutput:audioOutput];
    }
    _audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    /* video collector */
    AVCaptureDevice* videoDevice = [self cameraWithPosition:position];
    _devidePosition = videoDevice.position;
    _videoDevice = videoDevice;
    AVCaptureDeviceInput* videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if ([_captureSession canAddInput:videoInput]) {
        [_captureSession addInput:videoInput];
    }
    
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(_renderMgr.inputPixelFormat)};
    [videoOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
    //for not to discard any frame while recording video
    videoOutput.alwaysDiscardsLateVideoFrames = NO;
    
    if ([_captureSession canAddOutput:videoOutput]) {
        [_captureSession addOutput:videoOutput];
    }
    _videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //防抖功能
    if (YES == _videoConnection.supportsVideoStabilization) {
        if ([_videoConnection isVideoStabilizationSupported]) {
            _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        } else {
            // 8.0以上就用不上了,有强迫症,不能看到警告
//            self.videoConnection.enablesVideoStabilizationWhenAvailable = YES;
        }
    }
    
    //预览的摄像头分辨率设置
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
        _captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540;
    } else {
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }
    
    //设置帧率,对于单核的需要将帧率降低,如果还是不能满足就使用默认帧率
    CMTime frameDuration = kCMTimeInvalid;
    if ([NSProcessInfo processInfo].processorCount > 1) {
        frameDuration = CMTimeMake(1, 24);
    } else {
        frameDuration = CMTimeMake(1, 15);
    }
    NSError* error = nil;
    if ([videoDevice lockForConfiguration:&error]) {
        videoDevice.activeVideoMaxFrameDuration = frameDuration;
        videoDevice.activeVideoMinFrameDuration = frameDuration;
        [videoDevice unlockForConfiguration];
    } else {
        NSLog(@"videoDevice lockForConfiguration and use default frame error %@", error);
    }
    
    /* get recommand setting for audio device, video device and session */
    _audioCompressionSettings = [[audioOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie] copy];
    _videoCompressionSettings = [[videoOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie] copy];
    
    _videoOrientation = _videoConnection.videoOrientation;
}

- (void)teardownCaptureSession {
    if (_captureSession) {
        /* remove capture sesstion notification */
        [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_captureSession];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
        
        _captureSession = nil;
        _videoCompressionSettings = nil;
        _audioCompressionSettings = nil;
    }
}


#pragma --mark capture session notification
- (void)captureSessionNotification:(NSNotification *)notification {
    WeakSelf()
    dispatch_async(_sessionQueue, ^{
        if ([notification.name isEqualToString:AVCaptureSessionWasInterruptedNotification]) {
            [weakSelf captureSessionWasInterrupted];
        } else if ([notification.name isEqualToString:AVCaptureSessionInterruptionEndedNotification]) {
            [weakSelf captureSessionInterruptionEnded];
        } else if ([notification.name isEqualToString:AVCaptureSessionRuntimeErrorNotification]) {
            NSError* error = notification.userInfo[AVCaptureSessionErrorKey];
            [weakSelf captureSessionRuntimeError:error];
        } else if ([notification.name isEqualToString:AVCaptureSessionDidStartRunningNotification]) {
            [weakSelf captureSessionDidStartRunning];
        } else if ([notification.name isEqualToString:AVCaptureSessionDidStopRunningNotification]) {
            [weakSelf captureSessionDidStopRunning];
        }
    } );
}

#pragma --mark capture session event handle
- (void)captureSessionWasInterrupted {
    NSLog(@"-[%@ %@] capture session was interrupted", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self handleCaptureSessionStopRunning];
}

- (void)captureSessionInterruptionEnded {
    NSLog(@"-[%@ %@] capture session interruption ended", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)captureSessionRuntimeError:(NSError*)error {
    NSLog(@"-[%@ %@] capture session runtime error", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self handleCaptureSessionStopRunning];
    
    if (error.code == AVErrorDeviceIsNotAvailableInBackground) {
        if (_isRunning) {
            _startCaptureSessionOnEnteringForeground = YES;
        }
    } else if (error.code == AVErrorMediaServicesWereReset) {
        [self handleRecoverableCaptureSessionRuntimeError:error];
    } else {
        [self handleNonRecoverableCaptureSessionRuntimeError:error];
    }
}

- (void)captureSessionDidStartRunning {
    NSLog(@"-[%@ %@] capture session did started running", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)captureSessionDidStopRunning {
    NSLog(@"-[%@ %@] capture session did stopped running", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)handleCaptureSessionStopRunning {
    /* video */
    [self teardownVideoPipeline];
}

- (void)handleRecoverableCaptureSessionRuntimeError:(NSError*)error {
    if (_isRunning) {
        [_captureSession startRunning];
    }
}

- (void)handleNonRecoverableCaptureSessionRuntimeError:(NSError*)error {
    _isRunning = NO;
    [self teardownCaptureSession];
    
    @synchronized(self) {
        if (_capturePipelineDelegate) {
            WeakSelf()
            dispatch_async(_delegateCallbackQueue, ^{
                @autoreleasepool {
                    if ([weakSelf.capturePipelineDelegate respondsToSelector:@selector(capturePipeline:didStopRunningWithError:)]) {
                        [weakSelf.capturePipelineDelegate capturePipeline:weakSelf didStopRunningWithError:error];
                    }
                }
            });
        }
    }
}

//同步方法,保证视频渲染被关闭
- (void)teardownVideoPipeline {
    WeakSelf()
    dispatch_sync(_videoDataOutputQueue, ^{
        if (!weakSelf.outputVideoFormatDescription) {
            return;
        }
        
        [weakSelf.renderMgr reset];
        weakSelf.currentPreviewPixelBuffer = nil;
        
        [weakSelf videoPipelineDidFinishRunning];
    });
}

//开启后台任务(令后台运行大概3分钟左右)
- (void)videoPipelineWillStartRunning {
    if (_pipelineRunningTask != UIBackgroundTaskInvalid) {
        return;
    }
    
    _pipelineRunningTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"video background task new active");
    }];
}

//停掉后台任务
- (void)videoPipelineDidFinishRunning {
    if (_pipelineRunningTask == UIBackgroundTaskInvalid) {
        NSLog(@"should have a background task active");
        return;
    }
    
    /* end video background task */
    [[UIApplication sharedApplication] endBackgroundTask:_pipelineRunningTask];
    _pipelineRunningTask = UIBackgroundTaskInvalid;
}

#pragma --mark AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
    /* 媒体类型无关的类型的描述，可以支持音频和视频 */
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    if (connection == _videoConnection) {
        if (_outputVideoFormatDescription == nil) {
            //用一帧的事件去建立视频描述
            [self setupVideoPipelineWithInputFormatDescription:formatDescription];
        } else {
            /* 如果已经建立过视频描述,则可以进行预览和录制了 */
            [self renderVideoSampleBuffer:sampleBuffer];
        }
    } else if (connection == _audioConnection) {
        _outputAudioFormatDescription = formatDescription;
    }
}

#pragma --mark inner
- (void)setupVideoPipelineWithInputFormatDescription:(CMFormatDescriptionRef)inputFormatDescription {
    [self videoPipelineWillStartRunning];
    
    /* 媒体类型无关的类型的描述，可以支持音频和视频 */
    _videoDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription);
    
    [_renderMgr prepareForInputWithOutputDimensions:_videoDimensions];
    
    if (!_renderMgr.operatesInPlace && [_renderMgr respondsToSelector:@selector(outputFormatDescription)]) {
        _outputVideoFormatDescription = _renderMgr.outputFormatDescription;
    } else {
        _outputVideoFormatDescription = inputFormatDescription;
    }
}

- (void)renderVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef sourcePixelBuffer = nil;
    CVPixelBufferRef renderedPixelBuffer = nil;
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    [self calculateFpsByTimestamp:timestamp];
    
    @synchronized(_renderMgr) {
        if (self.renderingEnabled) {
            sourcePixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            // 进行滤镜处理
            renderedPixelBuffer = [_renderMgr copyRenderedPixelBuffer:sourcePixelBuffer];
        } else {
            return;
        }
    }
    
    @synchronized (self) {
        if (renderedPixelBuffer) {
            // output to preview
            [self outputPreviewPixelBuffer:renderedPixelBuffer];
            CFRelease(renderedPixelBuffer);
        } else if (sourcePixelBuffer){
            [self outputPreviewPixelBuffer:sourcePixelBuffer];
        } else {
            [self videoPipelineDidRunOutOfBuffers];
        }
    }
}

- (CGAffineTransform)transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)orientation withAutoMirroring:(BOOL)mirror {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Calculate offsets from an arbitrary reference orientation (portrait)
    CGFloat orientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation(orientation);
    CGFloat videoOrientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation(self.videoOrientation);
    
    // Find the difference in angle between the desired orientation and the video orientation
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation(angleOffset);
    
    if (_videoDevice.position == AVCaptureDevicePositionFront) {
        if ( mirror ) {
            transform = CGAffineTransformScale(transform, -1, 1);
        } else {
            if (UIInterfaceOrientationIsPortrait((UIInterfaceOrientation)orientation)) {
                transform = CGAffineTransformRotate(transform, M_PI);
            }
        }
    }
    
    return transform;
}

static CGFloat angleOffsetFromPortraitOrientationToOrientation(AVCaptureVideoOrientation orientation) {
    CGFloat angle = 0.0;
    
    switch (orientation) {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}

- (void)calculateFpsByTimestamp:(CMTime)timestamp {
    [_previousSecondTimestamps addObject:[NSValue valueWithCMTime:timestamp]];
    
    CMTime oneSecond = CMTimeMake(1, 1);
    CMTime oneSecondAgo = CMTimeSubtract(timestamp, oneSecond);
    
    while(CMTIME_COMPARE_INLINE([_previousSecondTimestamps[0] CMTimeValue], <, oneSecondAgo)) {
        [_previousSecondTimestamps removeObjectAtIndex:0];
    }
    
    if ([_previousSecondTimestamps count] > 1) {
        const Float64 duration = CMTimeGetSeconds(CMTimeSubtract([[_previousSecondTimestamps lastObject] CMTimeValue], [_previousSecondTimestamps[0] CMTimeValue]));
        const float newRate = (float)([_previousSecondTimestamps count] - 1) / duration;
        _videoFps = newRate;
    }
}

- (void)outputPreviewPixelBuffer:(CVPixelBufferRef)previewPixelBuffer {
    if (_capturePipelineDelegate) {
        // use the new frame buffer to make preview latency low
        self.currentPreviewPixelBuffer = previewPixelBuffer;
        
        WeakSelf()
        dispatch_async(_delegateCallbackQueue, ^{
            @autoreleasepool {
                CVPixelBufferRef previewPixelBuffer = NULL;
                @synchronized(self) {
                    previewPixelBuffer = weakSelf.currentPreviewPixelBuffer;
                    if (previewPixelBuffer) {
                        CFRetain(previewPixelBuffer);
                        weakSelf.currentPreviewPixelBuffer = NULL;
                    }
                }
                
                if (previewPixelBuffer) {
                    if ([weakSelf.capturePipelineDelegate respondsToSelector:@selector(capturePipeline:previewPixelBufferReadyForDisplay:)]) {
                        [weakSelf.capturePipelineDelegate capturePipeline:weakSelf previewPixelBufferReadyForDisplay:previewPixelBuffer];
                    }
                    CFRelease(previewPixelBuffer);
                }
            }
        });
    }
}

- (void)videoPipelineDidRunOutOfBuffers {
    /* pipeline buffer run out of, just to flush the data and stop */
    if (_capturePipelineDelegate) {
        WeakSelf()
        dispatch_async(_delegateCallbackQueue, ^{
            @autoreleasepool {
                if ([weakSelf.capturePipelineDelegate respondsToSelector:@selector(capturePipelineDidRunOutOfPreviewBuffers:)]) {
                    [weakSelf.capturePipelineDelegate capturePipelineDidRunOutOfPreviewBuffers:weakSelf];
                }
            }
        });
    }
}

//如果是运行中退到后台,切回前台的话,再开启摄像头
- (void)captureWillEnterForeground:(NSNotification*)notification {
    @synchronized(_renderMgr) {
        _renderingEnabled = YES;
    }
    
    WeakSelf()
    dispatch_sync(_sessionQueue, ^{
        if (weakSelf.startCaptureSessionOnEnteringForeground) {
            weakSelf.startCaptureSessionOnEnteringForeground = NO;
            if (weakSelf.isRunning) {
                [weakSelf.captureSession startRunning];
            }
        }
    });
}

- (void)captureWillEnterBackground:(NSNotification*)notification {
    @synchronized(_renderMgr) {
        _renderingEnabled = NO;
    }
}

/**
 * @brief 获取指定位置的摄像头,如果获取失败,则使用默认摄像头
 */
- (AVCaptureDevice*)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice* positionDevice = nil;
    for (AVCaptureDevice* device in devices) {
        if ([device position] == position)  {
            positionDevice = device;
            break;
        }
    }
    
    if (positionDevice == nil) {
        positionDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
    }
    
    return positionDevice;
}

@end
