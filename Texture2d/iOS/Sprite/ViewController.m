//
//  ViewController.m
//  Sprite
//
//  Created by Rinc Liu on 28/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "ViewController.h"
#import <SpriteSDK/SpriteSDK.h>

@interface ViewController ()<SpritePlayerDelegate>
@property(nonatomic,strong) SpritePlayer* spritePlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MTSpriteView* mtSpriteView = [[MTSpriteView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:mtSpriteView];
    _spritePlayer = [[SpritePlayer alloc]initWithMTSpriteView:mtSpriteView];
    
    //GLSpriteView* glSpriteView = [[GLSpriteView alloc]initWithFrame:self.view.frame];
    //[self.view addSubview:glSpriteView];
    //_spritePlayer = [[SpritePlayer alloc]initWithGLSpriteView:glSpriteView];
    
    _spritePlayer.delegate = self;
    [_spritePlayer playResource:@"bomb"];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_spritePlayer onDestroy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark SpritePlayerDelegate

-(void)onSpritePlayerStarted {
    NSLog(@"-> SpritePlayer started..");
}

-(void)onSpritePlayerPaused {
    NSLog(@"-> SpritePlayer paused..");
}

-(void)onSpritePlayerResumed {
    NSLog(@"-> SpritePlayer resumed..");
}

-(void)onSpritePlayerStopped {
    NSLog(@"-> SpritePlayer stopped..");
}

@end
