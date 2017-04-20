//
//  GLSaturationFilter.m
//  practicework
//
//  Created by bleach on 16/6/1.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLSaturationFilter.h"

NSString *const kSaturationFragmentShaderString = SHADER_STRING
(
    precision mediump float;
    uniform sampler2D uInputImageTexture;
    varying vec2 vTextureCoordinate;
    uniform lowp float uSaturation;
    const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
    void main() {
        lowp vec4 textureColor = texture2D(uInputImageTexture, vTextureCoordinate.st);
        lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
        lowp vec3 greyScaleColor = vec3(luminance);
        gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, uSaturation), textureColor.w);
    }
);

@implementation GLSaturationFilter {
    GLfloat saturation;
}

- (id)initWithSize:(CGSize)viewSize {
    id obj = [super initWithVertexShaderFromString:kBaseVertexShaderString fragmentShaderFromString:kSaturationFragmentShaderString viewSize:viewSize];
    [self initDefault];
    return obj;
}

- (void)initDefault {
    saturation = 0.5f;
    filterSaturationUniform = [baseProgram uniformIndex:@"uSaturation"];
}

- (void)doInit {
    baseTexture = [[GLTexture alloc] initNormalTexture:YES];
}

- (void)doRenderPrepare {
    [self setFloat:filterSaturationUniform floatValue:saturation];
}

- (void)setSaturation:(GLfloat)value {
    saturation = value;
}

@end
