//
//  SpriteView.m
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "GLSpriteView.h"
#import "GLSprite.h"

@interface GLSpriteView()

@property(nonatomic,strong) EAGLContext* glContext;
@property(nonatomic,assign) GLuint frameBuffer, colorRenderBuffer, depthRenderBuffer, stencilRenderBuffer;
@property(nonatomic,assign) GLint bufferWidth, bufferHeight;

@end

@implementation GLSpriteView

+(Class)layerClass {
    return [CAEAGLLayer class];
}

-(CAEAGLLayer*)glLayer {
    return (CAEAGLLayer*)self.layer;
}

- (CGFloat)scale {
    return UIScreen.mainScreen.scale;
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentScaleFactor = self.scale;
        
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_glContext];

        _bufferWidth = frame.size.width * self.scale;
        _bufferHeight = frame.size.height * self.scale;
        
        self.glLayer.opaque = NO;// Make layer transparent
        self.glLayer.drawableProperties = @{
            kEAGLDrawablePropertyRetainedBacking: @NO,
            kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
        };
        
        [self prepareBuffers];
    }
    return self;
}

-(void)onRender {
    [EAGLContext setCurrentContext:_glContext];
    
    glViewport(0, 0, _bufferWidth, _bufferHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    for (GLSprite* sprite in self.sprites) {
        [sprite drawInRect:rect];
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)onConfigChanged {
    _bufferWidth = self.frame.size.width * self.scale;
    _bufferHeight = self.frame.size.height * self.scale;
    [self releaseBuffers];
    [self prepareBuffers];
}

-(void)onDestroy {
    [self releaseBuffers];
    if ([EAGLContext currentContext] == _glContext) {
        [EAGLContext setCurrentContext:nil];
    }
}

-(void)prepareBuffers {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, _bufferWidth, _bufferHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.glLayer];
    
//    glGenRenderbuffers(1, &_depthRenderBuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
//    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _bufferWidth, _bufferHeight);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
      
    glGenRenderbuffers(1, &_stencilRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _stencilRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, _bufferWidth, _bufferHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _stencilRenderBuffer);
}

-(void)releaseBuffers {
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    if (_colorRenderBuffer) {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
//    if (_depthRenderBuffer) {
//        glDeleteRenderbuffers(1, &_depthRenderBuffer);
//        _depthRenderBuffer = 0;
//    }
    if (_stencilRenderBuffer) {
        glDeleteRenderbuffers(1, &_stencilRenderBuffer);
        _stencilRenderBuffer = 0;
    }
}

@end
