//
//  CapturePreview.h
//  practicework
//
//  Created by bleach on 16/5/16.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CapturePreview : UIView

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer isFrontCamera:(BOOL)isFrontCamera;
- (void)flushPixelBufferCache;
- (void)reset;


@end
