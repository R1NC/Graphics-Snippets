//
//  GLSprite.h
//  GLSprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SpriteBase.h"

@interface GLSprite : SpriteBase

@property(atomic,strong) GLKTextureInfo* texture;

-(void)drawInRect:(CGRect)rect;

@end
