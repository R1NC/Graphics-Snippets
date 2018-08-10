//
//  Sprite.h
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Sprite : NSObject

@property(nonatomic,assign) CGFloat angle, scale, transX, transY;

@property(nonatomic,strong) GLKTextureInfo* textureInfo;

-(void)drawInRect:(CGRect)rect;

-(void)onDestroy;

@end
