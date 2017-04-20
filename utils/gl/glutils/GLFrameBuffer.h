//
//  GLFrameBuffer.h
//  practicework
//
//  Created by bleach on 16/5/25.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 此类可用于离屏渲染,也可用于纹理更新
 */
@interface GLFrameBuffer : NSObject

@property (nonatomic, assign) GLuint bindTexture;

/**
 * @brief 设置帧缓冲区大小(使用默认的纹理配置和FBO)
 */
- (id)initWithSize:(CGSize)framebufferSize;

/**
 * @brief 设置帧缓冲区大小
 * @param fboTextureOptions 指定纹理配置
 * @parma onlyTexture       是否不是用FBO
 */
- (id)initWithSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)fboTextureOptions;

/**
 * @brief 设置帧缓冲区大小(完全当做一个纹理管理工具)
 * @param inputTexture 指定纹理
 */
- (id)initWithSize:(CGSize)framebufferSize inputTexture:(GLuint)inputTexture;

/**
 * @brief 激活FBO
 */
- (void)activateFramebuffer;

/**
 * @brief 不激活FBO
 */
- (void)deactiveFramebuffer;

@end
