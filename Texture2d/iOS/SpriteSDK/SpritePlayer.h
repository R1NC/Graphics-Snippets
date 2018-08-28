//
//  SpritePlayer.h
//  SpriteSDK
//
//  Created by Rinc Liu on 20/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTSpriteView.h"
#import "GLSpriteView.h"

@protocol SpritePlayerDelegate<NSObject>
@optional
-(void)onSproitePlayerStarted;
@optional
-(void)onSproitePlayerPaused;
@optional
-(void)onSproitePlayerResumed;
@optional
-(void)onSproitePlayerStopped;
@end

@interface SpritePlayer : NSObject

@property(nonatomic,weak) id<SpritePlayerDelegate> delegate;

-(instancetype)initWithMTSpriteView:(MTSpriteView*)spriteView;

-(instancetype)initWithGLSpriteView:(GLSpriteView*)spriteView __attribute__((deprecated));

-(void)playResource:(NSString*)resource;

-(void)onPause;

-(void)onResume;

-(void)onDestroy;

@end
