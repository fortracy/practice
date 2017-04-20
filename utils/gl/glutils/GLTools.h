//
//  GLTools.h
//  practicework
//
//  Created by bleach on 16/5/15.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLTools : NSObject

/**
 * @brief 根据文件名读取着色器文件
 */
+ (NSString *)readShaderFile:(NSString*)shaderName;

/**
 * @brief 根据文件路径读取着色器文件
 */
+ (NSString *)readShaderFileFromPath:(NSString *)shaderPath;

/**
 * @brief 创建一个pixelBuffer的缓冲区
 * @param width 
 * @param height
 * @param pixelFormat
 * @param maxBufferCount 缓冲区大小
 */
+ (CVPixelBufferPoolRef)createPixelBufferPool:(int32_t)width height:(int32_t)height pixelFormat:(FourCharCode)pixelFormat maxBufferCount:(int32_t)maxBufferCount;

/**
 * @brief 设置缓冲区大小阀值(注意需要release)
 */
+ (CFDictionaryRef)createPixelBufferPoolAuxAttributes:(int32_t)maxBufferCount;

/**
 * @brief 预先创建pixelBuffer,直到达到阀值
 */
+ (void)preallocatePixelBuffersInPool:(CVPixelBufferPoolRef)pool auxAttributes:(CFDictionaryRef)auxAttributes;

/**
 * @brief 是否支持加速
 */
+ (BOOL)supportsFastTextureUpload;

@end
