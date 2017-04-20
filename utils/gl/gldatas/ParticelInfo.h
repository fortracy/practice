//
//  ParticelInfo.h
//  practicework
//
//  Created by bleach on 16/6/26.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParticelInfo : NSObject

@property (nonatomic, assign) CGPoint postion;              //当前位置
@property (nonatomic, assign) GLfloat rotate;               //绕Z轴的旋转角度
@property (nonatomic, assign) GLfloat speedX;               //X轴偏移速度
@property (nonatomic, assign) GLfloat speedY;               //Y轴偏移速度
@property (nonatomic, assign) GLfloat maxScale;             //最终缩放值
@property (nonatomic, assign) GLfloat scaleFactor;          //缩放因子
@property (nonatomic, assign) GLfloat curScale;             //当前缩放值
@property (nonatomic, assign) GLfloat alpha;                //当前alpha值
@property (nonatomic, assign) GLfloat alphaFactor;          //alpha因子
@property (nonatomic, assign) GLuint imageIndex;            //图片索引

// V3
@property (nonatomic, assign) GLQuad* quadData;             //保存矩阵,减少计算量

@end
