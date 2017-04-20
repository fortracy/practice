//
//  GLProgram.h
//  practicework
//
//  Created by bleach on 16/5/25.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLProgram : NSObject

@property(nonatomic, readwrite) BOOL initialized;

/**
 * @brief 根据着色器初始化program
 */
- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderString:(NSString *)fShaderString;

/**
 * @brief 是否可用了
 */
- (BOOL)isProgramAvailable;

/**
 * @brief 链接着色器(将compile放在初始化中,而link独立开,可以在中间做其它操作)
 */
- (BOOL)link;

/**
 * @brief 使用着色器
 */
- (void)use;

/**
 * @brief 为着色器绑定attribute
 */
- (void)addAttribute:(NSString *)attributeName;

/**
 * @brief 根据attribute名获取attribute的索引
 */
- (GLuint)attributeIndex:(NSString *)attributeName;

/**
 * @brief 根据uniform名获取uniform的索引
 */
- (GLuint)uniformIndex:(NSString *)uniformName;

@end
