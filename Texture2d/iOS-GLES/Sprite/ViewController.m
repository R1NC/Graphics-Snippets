//
//  ViewController.m
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "ViewController.h"
#import "SpriteView.h"
#import "SpritePlayer.h"

@interface ViewController ()
@property(nonatomic,strong) SpritePlayer* spritePlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SpriteView* spriteView = [[SpriteView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view addSubview:spriteView];
    _spritePlayer = [[SpritePlayer alloc]initWithSpriteView:spriteView];
    [_spritePlayer playResource:@"bomb"];
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_spritePlayer onDestroy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
