//
//  GLSaturationFilter.h
//  practicework
//
//  Created by bleach on 16/6/1.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLBaseFilter.h"

@interface GLSaturationFilter : GLBaseFilter {
    GLfloat filterSaturationUniform;
}

- (void)setSaturation:(GLfloat)value;

@end
