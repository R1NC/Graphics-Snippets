//
//  MTSprite.h
//  MTSprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "SpriteBase.h"

@interface MTSprite : SpriteBase

@property(atomic,strong) id<MTLTexture> texture;

-(instancetype)initWithDevice:(id<MTLDevice>)device;

-(void)renderDrawable:(id<CAMetalDrawable>)drawable inRect:(CGRect)rect;

@end
