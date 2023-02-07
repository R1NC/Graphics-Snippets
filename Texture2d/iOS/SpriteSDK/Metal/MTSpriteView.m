//
//  MTSpriteView.m
//  MTSprite
//
//  Created by Rinc Liu on 23/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "MTSpriteView.h"
#import "MTSprite.h"

@implementation MTSpriteView

+(Class)layerClass {
    return [CAMetalLayer class];
}

-(CAMetalLayer*)metalLayer {
    return (CAMetalLayer*)self.layer;
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // An abstraction of GPU. Used to create buffers, textures, function libraries..
        _device = MTLCreateSystemDefaultDevice();
        
        // CAMetalLayer is a subclass of CALayer that knows how to display the contents of a Metal framebuffer.
        self.metalLayer.opaque = NO;// Make layer transparent
        self.metalLayer.device = _device;
        self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    for (MTSprite* sprite in self.sprites) {
        // In order to draw into the Metal layer, we first need to get a ‘drawable’ from the layer.
        // The drawable object manages a set of textures that are appropriate for rendering into.
        [sprite renderDrawable:[self.metalLayer nextDrawable] inRect:rect];
    }
}

-(void)onDestroy {
}

@end
