//
//  SVShaderUtilities.c
//  ShortVideo
//
//  Created by bleach on 15/5/22.
//  Copyright (c) 2015年 yy. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include "SVShaderUtilities.h"

void printGlError(GLuint name, int compile) {
    GLchar buf[1024];
    GLint length;
    if (compile) {
        glGetShaderInfoLog(name, 1024, &length, buf);
    } else {
        glGetProgramInfoLog(name, 1024, &length, buf);
    }
    printf("Shader error info: %s \n", buf);
}

void printGLInfoLog(GLuint name) {
    GLint logLength = 0;
    glGetShaderiv(name, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar buf[1024];
        GLint length;
        glGetShaderInfoLog(name, 1024, &length, buf);
        printf("GL info log: %s \n", buf);
    }
}

GLint glueCompileShader(GLenum target, GLsizei count, const GLchar **sources, GLuint *shader) {
	*shader = glCreateShader(target);	
	glShaderSource(*shader, count, sources, NULL);
	glCompileShader(*shader);
    
#if defined(DEBUG)
    printGLInfoLog(*shader);
#endif
    
    GLint status = GL_FALSE;
	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (GL_TRUE != status) {
        printGlError(*shader, 1);
	}
	
	return status;
}

GLint glueLinkProgram(GLuint program) {
	glLinkProgram(program);
	
#if defined(DEBUG)
    printGLInfoLog(program);
#endif
    
    GLint status = GL_FALSE;
	glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (GL_TRUE != status) {
        printGlError(program, 0);
    }
	
	return status;
}

GLint glueValidateProgram(GLuint program) {
	glValidateProgram(program);
    
#if defined(DEBUG)
    printGLInfoLog(program);
#endif
    
    GLint status = GL_FALSE;
	glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
    if (GL_TRUE == status) {
        printGlError(program, 0);
    }
    
	return status;
}

/* return named uniform location after linking */
GLint glueGetUniformLocation(GLuint program, const GLchar *uniformName) {
    GLint loc = glGetUniformLocation(program, uniformName);
    return loc;
}


/* compiles, links shaders and bind members */
GLint glueCreateProgram(const GLchar *vertSource, const GLchar *fragSource,
                        GLsizei attribNameCt, const GLchar **attribNames, 
                        const GLint *attribLocations,
                        GLsizei uniformNameCt, const GLchar **uniformNames, 
                        GLint *uniformLocations,
                        GLuint *program) {
    GLuint status = GL_FALSE;

    do {
        GLuint vertShader = 0;
        GLuint fragShader = 0;
        GLuint prog = 0;
        GLuint shaderMemberIndex = 0;
        
        prog = glCreateProgram();
        
        status = glueCompileShader(GL_VERTEX_SHADER, 1, &vertSource, &vertShader);
        if (GL_FALSE == status) {
            break;
        }
        
        status = glueCompileShader(GL_FRAGMENT_SHADER, 1, &fragSource, &fragShader);
        if (GL_FALSE == status) {
            break;
        }
        
        glAttachShader(prog, vertShader);
        
        glAttachShader(prog, fragShader);
        
        /* bind attibute before linking */
        for (shaderMemberIndex = 0; shaderMemberIndex < attribNameCt; shaderMemberIndex++) {
            if(strlen(attribNames[shaderMemberIndex])) {
                glBindAttribLocation(prog, attribLocations[shaderMemberIndex], attribNames[shaderMemberIndex]);
            }
        }
        
        status = glueLinkProgram(prog);
        if (GL_FALSE == status) {
            break;
        }
        
        for(shaderMemberIndex = 0; shaderMemberIndex < uniformNameCt; shaderMemberIndex++) {
            if(strlen(uniformNames[shaderMemberIndex])) {
                uniformLocations[shaderMemberIndex] = glueGetUniformLocation(prog, uniformNames[shaderMemberIndex]);
            }
        }
        *program = prog;
        
        if (vertShader) {
            glDeleteShader(vertShader);
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
        }
    } while (GL_FALSE);
    
	return status;
}
