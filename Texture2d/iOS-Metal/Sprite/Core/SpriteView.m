//
//  SpriteView.m
//  Sprite
//
//  Created by Rinc Liu on 23/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpriteView.h"
#import "Sprite.h"

@interface SpriteView()
@property(nonatomic,strong) CAMetalLayer *metalLayer;
@property(nonatomic,strong) id<CAMetalDrawable> currentDrawable;
@property(nonatomic,strong) Sprite* sprite;
@end

@implementation SpriteView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // An abstraction of GPU. Used to create buffers, textures, function libraries..
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        
        // CAMettalLayer to display the contents of a Matal framebuffer.
        _metalLayer = [CAMetalLayer layer];
        _metalLayer.frame = frame;
        _metalLayer.device = device;
        _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        [self.layer addSublayer:_metalLayer];
        
        _sprite = [[Sprite alloc] initWithDevice:device];
        
        self.contentScaleFactor = [UIScreen mainScreen].scale;
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    [_sprite renderDrawable:[self currentDrawable] inRect:rect];
    _currentDrawable = nil;
}

-(id<CAMetalDrawable>)currentDrawable {
    // CAMetalDrawable manages a set of textures that are appropriate for rendering into.
    // It may be nil if we're not on the screen or we've taken too long to render.
    while (_currentDrawable == nil) {
        _currentDrawable = [_metalLayer nextDrawable];
    }
    return _currentDrawable;
}

@end
