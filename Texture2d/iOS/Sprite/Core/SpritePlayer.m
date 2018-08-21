//
//  SpritePlayer.m
//  Sprite
//
//  Created by Rinc Liu on 20/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpritePlayer.h"
#import "Sprite.h"
#import "GLUtil.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioDuration : NSObject <NSCopying>
@property(nonatomic,assign) NSInteger begin, end;
@end

@implementation AudioDuration
-(id)copyWithZone:(NSZone*)zone{
    AudioDuration *ad = [[[self class] allocWithZone:zone] init];
    ad.begin = _begin;
    ad.end = _end;
    return ad;
}
@end

@interface SpritePlayer()
@property(nonatomic,strong) SpriteView* spriteView;
@property(nonatomic,copy) NSString* frameFolder;
@property(nonatomic,assign) NSInteger frameIndex, frameCount;
@property(nonatomic,assign) BOOL rendering, paused, destroyed;
@property(nonatomic,assign) CGFloat frameScale;
@property(nonatomic,assign) NSTimeInterval frameDuration;
@property(nonatomic,strong) NSMutableDictionary* audioMap;
@end

@implementation SpritePlayer

-(instancetype)initWithSpriteView:(SpriteView*)spriteView {
    if (self = [super init]) {
        _spriteView = spriteView;
        _frameScale = 1.f;
        _audioMap = [NSMutableDictionary new];
    }
    return self;
}

-(void)playResource:(NSString*)resource {
    _frameIndex = 0;
    _frameCount = 0;
    _frameFolder = resource;
    [self releaseAllAudios];
    [self releaseSprites:true];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self parseConfig]) {
            weakSelf.paused = NO;
            [self startRender];
            if (weakSelf.delegate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate onSproitePlayerStarted];
                });
            }
        }
    });
}

-(void)onPause {
    [self pauseAllAudios];
    _paused = YES;
}

-(void)onResume {
    [self startRender];
}

-(void)onDestroy {
    [self releaseSprites:false];
    [self pauseAllAudios];
    [self releaseAllAudios];
    _destroyed = YES;
}

-(void)startRender {
    if (_rendering || !_frameFolder || _frameCount <= 0 || (_frameIndex > _frameCount - 1)) return;
    if (!_paused) {
        if (_delegate) [_delegate onSproitePlayerResumed];
        _paused = NO;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self renderIfNeeded];
        
        weakSelf.rendering = NO;
        [self pauseAllAudios];
        if (!weakSelf.destroyed) {
            if (weakSelf.delegate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.paused) {
                        [weakSelf.delegate onSproitePlayerPaused];
                    } else {
                        [weakSelf.delegate onSproitePlayerStopped];
                        for (Sprite* sprite in weakSelf.spriteView.sprites) {
                            sprite.scale = 0;
                        }
                        [weakSelf refreshSpriteView];
                    }
                });
            }
        }
    });
}

-(void)renderIfNeeded {
    if (!_paused && !_destroyed && (_frameIndex <= _frameCount - 1)) {
        NSTimeInterval t0 = [[NSDate date] timeIntervalSince1970];
        
        for (AudioDuration* ad in _audioMap.allKeys) {
            AVPlayer* player = _audioMap[ad];
            if (_frameIndex >= ad.begin && _frameIndex <= ad.end) {
                [self resumeAudio:player];
            } else if (_frameIndex > ad.end) {
                [self pauseAudio:player];
            }
        }
        
        for (Sprite* sprite in _spriteView.sprites) {
            sprite.scale = _frameScale;
            NSTimeInterval tx = [[NSDate date] timeIntervalSince1970];
            NSString* imgName = [NSString stringWithFormat:@"%@-%ld", _frameFolder, _frameIndex % _frameCount];
            NSString* imgPath = [self pathWithFileName:imgName type:@"png"];
            UIImage* img = [UIImage imageWithContentsOfFile:imgPath];
            if (img) {
                sprite.textureInfo = [GLUtil textureInfoWithImage:img];
            }
            NSLog(@"Load png %@ cost:%f imgNil:%d textureNil:%d", imgName, ([[NSDate date] timeIntervalSince1970] - tx), img==nil, sprite.textureInfo==nil);
        }
        
        [self refreshSpriteView];
        
        NSTimeInterval t1 = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval delay = 0;
        if (t1 - t0 < _frameDuration) {
            delay = _frameDuration + t0 - t1;
            _frameIndex++;
        } else {
            _frameIndex += (t1 - t0) / _frameDuration;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay/1000 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self renderIfNeeded];
        });
    }
}

-(void)refreshSpriteView {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.spriteView setNeedsDisplay];
    });
}

-(AVPlayer*)createPlayerWithFile:(NSString*)file {
    AVPlayer* player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:[self pathWithFileName:file type:@"mp3"]]];
    return player;
}

-(void)resumeAudio:(AVPlayer*)player {
    if (player) {
        AVAudioSession* session = [AVAudioSession sharedInstance];
        NSError* err;
        [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&err];
        if (err) {
            NSLog(@"AVPlayer setCategory error: %@", err.localizedDescription);
        }
        [session setActive:YES error:&err];
        if (err) {
            NSLog(@"AVPlayer setSessionActive error: %@", err.localizedDescription);
        }
        [player setRate:1.0f];
        if (@available(iOS 10.0, *)) {
            [player playImmediatelyAtRate:1.0];
        } else {
            [player play];
        }
    }
}

-(void)pauseAudio:(AVPlayer*)player {
    if (player) {
        [player setRate:0.0f];
    }
}

-(void)pauseAllAudios {
    for (AVPlayer* player in _audioMap.allValues) {
        [self pauseAudio:player];
    }
}

-(void)releaseAllAudios {
    for (AVPlayer* player in _audioMap.allValues) {
        if (player) {
            [player replaceCurrentItemWithPlayerItem:nil];
        }
    }
    [_audioMap removeAllObjects];
}

-(void)releaseSprites:(BOOL)reset {
    for (Sprite* sprite in _spriteView.sprites) {
        [sprite onDestroy];
    }
    [_spriteView.sprites removeAllObjects];
    if (reset) {
        [_spriteView.sprites addObject:[Sprite new]];
    }
}

-(BOOL)parseConfig {
    NSString* json = [self stringWithFileName:[NSString stringWithFormat:@"%@-config", _frameFolder] type:@"json"];
    if (json) {
        NSDictionary* dict = [self dictFromJson:json];
        if (dict) {
            _frameCount = [dict[@"count"] integerValue];
            if (_frameCount > 0) {
                _frameScale = [dict[@"scale"] floatValue];
                _frameDuration = [dict[@"duration"] integerValue];
                NSArray* audios = dict[@"audio"];
                if (audios) {
                    for (NSDictionary* d in audios) {
                        AudioDuration* ad = [AudioDuration new];
                        ad.begin = [d[@"begin"] integerValue];
                        ad.end = [d[@"end"] integerValue];
                        NSString* af = [NSString stringWithFormat:@"%@-%@", _frameFolder, d[@"file"]];
                        _audioMap[ad] = [self createPlayerWithFile:af];
                    }
                }
                return YES;
            }
        }
    }
    return NO;
}

-(NSString*)pathWithFileName:(NSString*)name type:(NSString*)type {
    return [[NSBundle mainBundle] pathForResource:name ofType:type];
}

-(NSString*)stringWithFileName:(NSString*)name type:(NSString*)type {
    return [NSString stringWithContentsOfFile:[self pathWithFileName:name type:type] encoding:NSUTF8StringEncoding error:nil];
}

-(NSDictionary*)dictFromJson:(NSString*)json {
    NSError *err;
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
}

@end
