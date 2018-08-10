//
//  SpriteView.m
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpriteView.h"
#import "Sprite.h"
#import <GLKit/GLKit.h>
#import "GLUtil.h"

@interface SpriteView()<GLKViewDelegate>
@property(nonatomic,strong) Sprite* sprite;
@end

@implementation SpriteView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.delegate = self;
        [self prepareGLContext];
        [self setupDrawableConfig];
        _sprite = [Sprite new];
        _sprite.textureInfo = [GLUtil textureInfoWithImage:[UIImage imageNamed:@"Sprite"]];
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
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, rect.size.width, rect.size.height);
    [_sprite drawInRect:rect];
}

@end
