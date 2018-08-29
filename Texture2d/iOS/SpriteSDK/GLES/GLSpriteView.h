//
//  GLSpriteView.h
//  GLSprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <GLKit/GLKit.h>

__deprecated_msg("OpenGL ES API is deprecated, use Metal API 'MTSpriteView' instead.")
@interface GLSpriteView : GLKView

@property(nonatomic,strong,readonly) NSMutableArray* sprites;

@end
