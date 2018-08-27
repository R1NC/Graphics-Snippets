//
//  SpriteView.m
//  Sprite
//
//  Created by Rinc Liu on 23/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpriteView.h"
#import "Sprite.h"

@interface SpriteView()<MTKViewDelegate>
@property(nonatomic,strong) Sprite* sprite;
@end

@implementation SpriteView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // An abstraction of GPU. Used to create buffers, textures, function libraries..
        self.device = MTLCreateSystemDefaultDevice();
        self.delegate = self;
        self.framebufferOnly = YES;
        self.autoResizeDrawable = YES;
        self.clearColor = MTLClearColorMake(0, 0, 0, 0);
        self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        self.contentScaleFactor = UIScreen.mainScreen.scale;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // Although CALayers are non-opaque by default, CAMetalLayer is opaque by default.
        // So we need to expressly set layer.opaque to false in order to draw transparent content with Metal.
        self.layer.opaque = false;
        
        _sprite = [[Sprite alloc] initWithDevice:self.device];
    }
    return self;
}

#pragma mark MTKViewDelegate

-(void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
}

-(void)drawInMTKView:(MTKView*)view {
    [_sprite renderDrawable:self.currentDrawable inRect:self.frame];
}

@end
