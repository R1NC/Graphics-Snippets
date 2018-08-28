//
//  SpriteBase.m
//  SpriteSDK
//
//  Created by Rinc Liu on 28/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpriteBase.h"

@implementation SpriteBase

-(instancetype)init {
    if (self = [super init]) {
        _transX = 0.0f;
        _transY = 0.0f;
        _angle = 0.0f;
        _scale = 1.0f;
    }
    return self;
}

-(void)onDestroy {
}

@end
