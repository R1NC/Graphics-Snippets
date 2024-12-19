//
//  SpriteViewBase.m
//  SpriteSDK
//
//  Created by Rinc Liu on 29/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpriteViewBase.h"

@interface SpriteViewBase()

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation SpriteViewBase

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _sprites = [NSMutableArray new];
        self.contentScaleFactor = 1.0f;//By default, it is 2.0 for retina displays. And this will make texture only one quadrant of the screen!
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onRender)];
        [_displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];

        [UIDevice.currentDevice beginGeneratingDeviceOrientationNotifications];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:UIDevice.currentDevice];
    }
    return self;
}

-(void)onRender {
}

-(void)onOrientationChanged:(NSNotification*)notify {
    [self onConfigChanged];
}

-(void)onDestroy {
}

- (void)dealloc {
    [UIDevice.currentDevice endGeneratingDeviceOrientationNotifications];
    [_displayLink invalidate];
}

@end
