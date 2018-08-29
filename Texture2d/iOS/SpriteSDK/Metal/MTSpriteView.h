//
//  MTSpriteView.h
//  MTSprite
//
//  Created by Rinc Liu on 23/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Metal/Metal.h>
#import "SpriteViewBase.h"

@interface MTSpriteView : SpriteViewBase

@property(nonatomic,strong,readonly) id<MTLDevice> device;

@end
