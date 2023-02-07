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

-(CALayer*)makeBackingLayer {
    return [CAMetalLayer layer];
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.wantsLayer = YES; //Triggering makeBackingLayer to create a Metal Layer
        // An abstraction of GPU. Used to create buffers, textures, function libraries..
        _device = MTLCreateSystemDefaultDevice();
        
        // CAMetalLayer is a subclass of CALayer that knows how to display the contents of a Metal framebuffer.
        CAMetalLayer *metalLayer = (CAMetalLayer*)self.layer;
        metalLayer.opaque = NO;// Make layer transparent
        metalLayer.device = _device;
        metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    for (MTSprite* sprite in self.sprites) {
        // In order to draw into the Metal layer, we first need to get a ‘drawable’ from the layer.
        // The drawable object manages a set of textures that are appropriate for rendering into.
        [sprite renderDrawable:[(CAMetalLayer*)self.layer nextDrawable] inRect:rect];
    }
}

-(void)onDestroy {
}

@end
