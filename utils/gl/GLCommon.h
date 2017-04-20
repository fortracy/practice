//
//  GLCommon.h
//  practicework
//
//  Created by bleach on 16/5/25.
//  Copyright © 2016年 duowan. All rights reserved.
//

#ifndef GLCommon_h
#define GLCommon_h

typedef struct GLTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
    GLboolean mimap;
} GLTextureOptions;

typedef struct GLColor {
    GLfloat red;
    GLfloat green;
    GLfloat blue;
    GLfloat alpha;
} GLColor;

typedef struct GLVertex4 {
    GLfloat vx;
    GLfloat vy;
    GLfloat vz;
    GLfloat vw;
} GLVertex4;

typedef struct GLTexcoord2 {
    GLfloat tx;
    GLfloat ty;
} GLTexcoord2;

typedef struct GLPackData {
    GLVertex4 vertex;
    GLTexcoord2 texcoord;
    GLfloat alpha;
} GLPackData;

typedef struct GLQuad {
    GLPackData data[4];
} GLQuad;

static inline void runSynchronouslySpecifyQueue(dispatch_queue_t queue, void (^block)(void))
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == queue)
#pragma clang diagnostic pop
    {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

static inline void runAsynchronouslySpecifyQueue(dispatch_queue_t queue, void (^block)(void))
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == queue)
#pragma clang diagnostic pop
    {
        block();
    } else {
        dispatch_async(queue, block);
    }
}

#endif /* GLCommon_h */
