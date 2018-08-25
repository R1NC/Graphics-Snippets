//
//  Sprite.h
//  Sprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

@interface Sprite : NSObject

@property(atomic,assign) CGFloat angle, scale, transX, transY;

-(instancetype)initWithDevice:(id<MTLDevice>)device;

-(void)renderDrawable:(id<CAMetalDrawable>)drawable inRect:(CGRect)rect;

@end
