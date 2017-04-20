//
//  GLGrayFilter.m
//  practicework
//
//  Created by bleach on 16/6/1.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLGrayFilter.h"

NSString *const kGrayFragmentShaderString = SHADER_STRING
(
    precision mediump float;
    varying vec2 vTextureCoordinate;
    uniform sampler2D uInputImageTexture;
    void main() {
        vec4 col = texture2D(uInputImageTexture, vTextureCoordinate.st);
        float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));
        gl_FragColor = vec4(grey, grey, grey, col.a);
    }
);

@implementation GLGrayFilter

- (id)initWithSize:(CGSize)viewSize {
    return [super initWithVertexShaderFromString:kBaseVertexShaderString fragmentShaderFromString:kGrayFragmentShaderString viewSize:viewSize];
}

- (void)doInit {
    baseTexture = [[GLTexture alloc] initNormalTexture:YES];
}


@end
