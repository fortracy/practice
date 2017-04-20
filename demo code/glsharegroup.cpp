#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>


struct OpenGLContext
{
    GLint Width;
    GLint Height;

    GLuint RenderBuffer;
    GLuint FrameBuffer;
    GLuint DepthBuffer;

    UIView* View;
    EAGLContext* MainContext;
    EAGLContext* WorkingContext;
    EAGLSharegroup* Sharegroup;	

    // Trivial constructor.
    OpenGLContext();

    // Call on the main thread before use.
    // I call it in layoutSubviews.
    // view must not be nil.
    void MainInit(UIView* view);

    // Call on the rendering thread before use, but
    // after MainInit();
    void InitOnSecondaryThread();	

    // Call before any OpenGL ES calls, at the
    // beginning of each frame.
    void PrepareBuffers();

    // Present frame. Call at the end of each
    // frame.
    void SwapBuffers();
};

OpenGLContext::OpenGLContext()
{
    Width = 0;
    Height = 0;

    RenderBuffer = 0;
    FrameBuffer = 0;
    DepthBuffer = 0;

    View = 0;
    MainContext = 0;
    WorkingContext = 0;
    Sharegroup = 0;	
}

void OpenGLContext::InitOnSecondaryThread()
{
    EAGLSharegroup* group = MainContext.sharegroup;
    if (!group)
    {
    	NSLog(@"Could not get sharegroup from the main context");
    }
    WorkingContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1 sharegroup:group];
    if (!WorkingContext || ![EAGLContext setCurrentContext:WorkingContext]) {
    	NSLog(@"Could not create WorkingContext");
    }
}

void OpenGLContext::MainInit(UIView* view)
{
    View = view;
    MainContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

    if (!MainContext || ![EAGLContext setCurrentContext:MainContext]) {
    	NSLog(@"Could not create EAGLContext");	
    	return;
    }
    NSLog(@"Main EAGLContext created");		

    glGenFramebuffersOES(1, &FrameBuffer);
    glGenRenderbuffersOES(1, &RenderBuffer);
    glGenRenderbuffersOES(1, &DepthBuffer);

    glBindFramebufferOES(GL_FRAMEBUFFER_OES, FrameBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, RenderBuffer);

    if (![MainContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)View.layer])
    {
    	NSLog(@"error calling MainContext renderbufferStorage");
    	return;
    }

    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, RenderBuffer);

    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &Width);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &Height);

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, DepthBuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, Width, Height);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, DepthBuffer);

    glFlush();

    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
    	NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
    }

    WorkingContext = MainContext;
}

void OpenGLContext::PrepareBuffers()
{   
    if (!WorkingContext || [EAGLContext setCurrentContext:WorkingContext] == NO)
    {
    	NSLog(@"PrepareBuffers: [EAGLContext setCurrentContext:WorkingContext] failed");
    	return;
    }
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, FrameBuffer);	
}

void OpenGLContext::SwapBuffers()
{
    if (!WorkingContext || [EAGLContext setCurrentContext:WorkingContext] == NO)
    {
    	NSLog(@"SwapBuffers: [EAGLContext setCurrentContext:WorkingContext] failed");
    	return;
    }

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, RenderBuffer);

    if([WorkingContext presentRenderbuffer:GL_RENDERBUFFER_OES] == NO)
    {
    	NSLog(@"SwapBuffers: [WorkingContext presentRenderbuffer:GL_RENDERBUFFER_OES] failed");
    }	
}