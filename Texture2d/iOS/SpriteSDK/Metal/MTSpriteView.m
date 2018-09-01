//
//  MTSpriteView.m
//  MTSprite
//
//  Created by Rinc Liu on 23/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "MTSpriteView.h"
#import "MTSprite.h"

@interface MTSpriteView()
@property(nonatomic,strong) CAMetalLayer* metalLayer;
@end

@implementation MTSpriteView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // An abstraction of GPU. Used to create buffers, textures, function libraries..
        _device = MTLCreateSystemDefaultDevice();
        
        // CAMetalLayer is a subclass of CALayer that knows how to display the contents of a Metal framebuffer.
        _metalLayer = [CAMetalLayer layer];
        _metalLayer.frame = self.bounds;
        _metalLayer.opaque = NO;// Make layer transparent
        _metalLayer.device = _device;
        _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        [self.layer addSublayer:_metalLayer];
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    for (MTSprite* sprite in self.sprites) {
        // In order to draw into the Metal layer, we first need to get a ‘drawable’ from the layer.
        // The drawable object manages a set of textures that are appropriate for rendering into.
        [sprite renderDrawable:[_metalLayer nextDrawable] inRect:rect];
    }
}

-(void)onDestroy {
}

@end
