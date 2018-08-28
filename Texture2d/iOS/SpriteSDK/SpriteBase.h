//
//  SpriteBase.h
//  SpriteSDK
//
//  Created by Rinc Liu on 28/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpriteBase : NSObject

@property(atomic,assign) float angle, scale, transX, transY;

-(instancetype)init;

-(void)onDestroy;

@end
