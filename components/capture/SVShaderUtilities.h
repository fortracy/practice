//
//  SVShaderUtilities.h
//  ShortVideo
//
//  Created by bleach on 15/5/22.
//  Copyright (c) 2015年 yy. All rights reserved.
//

#ifndef GL_SVShaderUtilities_h
#define GL_SVShaderUtilities_h
    
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

GLint glueCompileShader(GLenum target, GLsizei count, const GLchar **sources, GLuint *shader);
GLint glueLinkProgram(GLuint program);
GLint glueValidateProgram(GLuint program);
GLint glueGetUniformLocation(GLuint program, const GLchar *name);

GLint glueCreateProgram(const GLchar *vertSource, const GLchar *fragSource,
                        GLsizei attribNameCt, const GLchar **attribNames, 
                        const GLint *attribLocations,
                        GLsizei uniformNameCt, const GLchar **uniformNames,
                        GLint *uniformLocations,
                        GLuint *program);

#endif /* GL_SVShaderUtilities_h */