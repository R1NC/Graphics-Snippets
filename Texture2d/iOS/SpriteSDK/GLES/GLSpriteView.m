//
//  SpriteView.m
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "GLSpriteView.h"
#import "GLSprite.h"
#import <GLKit/GLKit.h>

@interface GLSpriteView()<GLKViewDelegate>
@end

@implementation GLSpriteView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.delegate = self;
        self.contentScaleFactor = 1.0f;//By default, it is 2.0 for retina displays. And this will make texture only one quadrant of the screen!
        [self prepareGLContext];
        [self setupDrawableConfig];
        _sprites = [NSMutableArray new];
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    }
    return self;
}

-(void)prepareGLContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
}

-(void)setupDrawableConfig {
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    self.drawableMultisample = GLKViewDrawableMultisample4X;
}

#pragma mark GLKViewDelegate

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glViewport(0, 0, rect.size.width, rect.size.height);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    for (GLSprite* sprite in _sprites) {
        [sprite drawInRect:rect];
    }
}

@end
