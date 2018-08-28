//
//  SpriteView.h
//  Sprite
//
//  Created by Rinc Liu on 23/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

@interface SpriteView : MTKView

@property(nonatomic,strong,readonly) NSMutableArray* sprites;

@end
