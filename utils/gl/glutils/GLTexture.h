//
//  GLTexture.h
//  practicework
//
//  Created by bleach on 16/5/31.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLTexture : NSObject

@property (nonatomic, assign) GLuint bindTexture;

- (id)initNormalTexture:(BOOL)normalTexture;

- (id)initWithOptions:(GLTextureOptions)fboTextureOptions normalTexture:(BOOL)normalTexture;

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)updateTextureWithUIImage:(UIImage *)image;

- (void)updatePvrTextureWithName:(NSString *)pvrFilePath;

- (void)updateTextureWithImageData:(SImageData *)cacheImageData;

@end
