//
//  SpriteViewBase.h
//  SpriteSDK
//
//  Created by Rinc Liu on 29/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpriteViewBase : UIView

@property(nonatomic,strong,readonly) NSMutableArray* sprites;

-(instancetype)initWithFrame:(CGRect)frame;

-(void)onOrientationChanged;

-(void)onRender;

-(void)onDestroy;

@end
