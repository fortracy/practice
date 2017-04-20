//
//  GlobalMacros.h
//  practicework
//
//  Created by bleach on 16/5/14.
//  Copyright © 2016年 duowan. All rights reserved.
//

#ifndef GlobalMacros_h
#define GlobalMacros_h

#pragma mark - GL
#define STRINGIZE(x) #x
#define SHADER_STRING(text) @ STRINGIZE(text)

static inline const char * GetGLErrorString(GLenum error) {
    const char *str;
    switch(error) {
        case GL_NO_ERROR:
            str = "GL_NO_ERROR";
            break;
        case GL_INVALID_ENUM:
            str = "GL_INVALID_ENUM";
            break;
        case GL_INVALID_VALUE:
            str = "GL_INVALID_VALUE";
            break;
        case GL_INVALID_OPERATION:
            str = "GL_INVALID_OPERATION";
            break;
#if defined __gl_h_ || defined __gl3_h_
        case GL_OUT_OF_MEMORY:
            str = "GL_OUT_OF_MEMORY";
            break;
        case GL_INVALID_FRAMEBUFFER_OPERATION:
            str = "GL_INVALID_FRAMEBUFFER_OPERATION";
            break;
#endif
#if defined __gl_h_
        case GL_STACK_OVERFLOW:
            str = "GL_STACK_OVERFLOW";
            break;
        case GL_STACK_UNDERFLOW:
            str = "GL_STACK_UNDERFLOW";
            break;
        case GL_TABLE_TOO_LARGE:
            str = "GL_TABLE_TOO_LARGE";
            break;
#endif
        default:
            str = "(ERROR: Unknown Error Enum)";
            break;
    }
    return str;
}

#define GetGLError()									\
{														\
    GLenum err = glGetError();							\
    while (err != GL_NO_ERROR) {						\
        NSLog(@"GLError %s set in File:%s Line:%d\n",   \
        GetGLErrorString(err), __FILE__, __LINE__);	    \
        err = glGetError();								\
    }													\
}

#pragma mark - OC
#define WeakSelf() __weak typeof(self) weakSelf = self;

#pragma mark - CostTime
#define DoCostTime(func, funcName)                                  \
CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();              \
func;                                                               \
CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime); \
NSLog(@"%@ cost time in %f ms", funcName, linkTime * 1000.0);       \

#endif /* GlobalMacros_h */
