//
//  SpriteViewBase.m
//  SpriteSDK
//
//  Created by Rinc Liu on 29/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpriteViewBase.h"

@implementation SpriteViewBase

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _sprites = [NSMutableArray new];
        self.contentScaleFactor = 1.0f;//By default, it is 2.0 for retina displays. And this will make texture only one quadrant of the screen!
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    }
    return self;
}

@end
