//
//  ParticelInfo.m
//  practicework
//
//  Created by bleach on 16/6/26.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "ParticelInfo.h"

@implementation ParticelInfo

- (id)init {
    if (self = [super init]) {
        _postion = CGPointMake(0.0f, 0.0f);
        _rotate = 90.0f;
        _speedX = 0.0f;
        _speedY = 0.0f;
        _maxScale = 0.0f;
        _scaleFactor = 0.5f;
        _curScale = 0.0f;
        _alpha = 1.0f;
        _alphaFactor = 0.01f;
        _imageIndex = 0;
        _quadData = (GLQuad *)malloc(sizeof(GLQuad));
    }
    
    return self;
}

- (void)dealloc{
    free(_quadData);
    _quadData = NULL;
}

@end
