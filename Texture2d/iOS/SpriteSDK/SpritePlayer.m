//
//  SpritePlayer.m
//  SpriteSDK
//
//  Created by Rinc Liu on 20/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "SpritePlayer.h"
#import "MTSprite.h"
#import "GLSprite.h"
#import "MTUtil.h"
#import "GLUtil.h"
#import <AVFoundation/AVFoundation.h>

#define CURRENT_TIME_MILLIS [[NSDate date]timeIntervalSince1970]*1000

typedef NS_ENUM(NSInteger, TextureFormat) {
    TextureFormatPNG,
    TextureFormatPVR
};

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
@property(nonatomic,strong) MTSpriteView* mtSpriteView;
@property(nonatomic,strong) GLSpriteView* glSpriteView;
@property(nonatomic,copy) NSString* frameFolder;
@property(nonatomic,assign) NSInteger frameIndex, frameCount;
@property(nonatomic,assign) BOOL rendering, paused, destroyed;
@property(nonatomic,assign) CGFloat frameScale;
@property(nonatomic,assign) NSTimeInterval frameDuration;
@property(nonatomic,strong) NSMutableDictionary* audioMap;
@property(nonatomic,assign) TextureFormat textureFormat;
@end

@implementation SpritePlayer

-(instancetype)initWithMTSpriteView:(MTSpriteView*)mtSpriteView {
    if (self = [super init]) {
        _mtSpriteView = mtSpriteView;
        [self initialize];
    }
    return self;
}

-(instancetype)initWithGLSpriteView:(GLSpriteView*)glSpriteView {
    if (self = [super init]) {
        _glSpriteView = glSpriteView;
        [self initialize];
    }
    return self;
}

-(void)initialize {
    _frameScale = 1.f;
    _audioMap = [NSMutableDictionary new];
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
    if (_paused) {
        if (_delegate) [_delegate onSpritePlayerResumed];
        _paused = NO;
    } else {
        if (_delegate) [_delegate onSpritePlayerStarted];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self renderIfNeeded];
    });
}

-(void)renderIfNeeded {
    if (!_paused && !_destroyed && (_frameIndex <= _frameCount - 1)) {
        NSTimeInterval t0 = CURRENT_TIME_MILLIS;
        
        for (AudioDuration* ad in _audioMap.allKeys) {
            AVPlayer* player = _audioMap[ad];
            if (_frameIndex >= ad.begin && _frameIndex <= ad.end) {
                [self resumeAudio:player];
            } else if (_frameIndex > ad.end) {
                [self pauseAudio:player];
            }
        }
        
        if (_mtSpriteView) {
            for (MTSprite* sprite in _mtSpriteView.sprites) {
                sprite.scale = _frameScale;
                NSTimeInterval tx = CURRENT_TIME_MILLIS;
                sprite.texture = [MTUtil loadTextureWithImagePath:[self imagePathWithFolder:_frameFolder index:(_frameIndex%_frameCount) format:_textureFormat] device:_mtSpriteView.device];
                NSLog(@"Metal load %@-%ld cost:%fms textureNil:%d", _frameFolder, (_frameIndex%_frameCount), (CURRENT_TIME_MILLIS - tx), sprite.texture==nil);
            }
        } else if (_glSpriteView) {
            for (GLSprite* sprite in _glSpriteView.sprites) {
                sprite.scale = _frameScale;
                NSTimeInterval tx = CURRENT_TIME_MILLIS;
                sprite.texture = [GLUtil loadTextureWithImagePath:[self imagePathWithFolder:_frameFolder index:(_frameIndex%_frameCount) format:_textureFormat]];
                NSLog(@"GLES load %@-%ld cost:%fms textureNil:%d", _frameFolder, (_frameIndex%_frameCount), (CURRENT_TIME_MILLIS - tx), sprite.texture==nil);
            }
        }
        
        [self refreshSpriteView];
        
        NSTimeInterval t1 = CURRENT_TIME_MILLIS;
        NSTimeInterval delay = 0;
        if (t1 - t0 < _frameDuration) {
            delay = _frameDuration + t0 - t1;
            _frameIndex++;
        } else {
            _frameIndex += _skipFrame ? (t1 - t0) / _frameDuration : 1;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay/1000 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self renderIfNeeded];
        });
    } else {
        _rendering = NO;
        [self pauseAllAudios];
        if (!_destroyed) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.paused) {
                    if (weakSelf.delegate) [weakSelf.delegate onSpritePlayerPaused];
                } else {
                    if (weakSelf.delegate) [weakSelf.delegate onSpritePlayerStopped];
                    if (weakSelf.mtSpriteView) {
                        for (MTSprite* sprite in weakSelf.mtSpriteView.sprites) {
                            sprite.scale = 0;
                        }
                    } else if (weakSelf.glSpriteView) {
                        for (GLSprite* sprite in weakSelf.glSpriteView.sprites) {
                            sprite.scale = 0;
                        }
                    }
                    [weakSelf refreshSpriteView];
                }
            });
        }
    }
}

-(NSString*)imagePathWithFolder:(NSString*)folder index:(NSInteger)index format:(TextureFormat)format {
    NSString* imgName = [NSString stringWithFormat:@"%@-%ld", folder, index];
    switch (format) {
        case TextureFormatPNG:
            return [self pathWithFileName:imgName type:@"png"];
        case TextureFormatPVR:
            return [self pathWithFileName:imgName type:@"pvr"];
    }
}

-(void)refreshSpriteView {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.mtSpriteView) {
            [weakSelf.mtSpriteView setNeedsDisplay];
        } else if (weakSelf.glSpriteView) {
            [weakSelf.glSpriteView setNeedsDisplay];
        }
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
        /*if (err) {
            NSLog(@"AVPlayer setCategory error: %@", err.localizedDescription);
        }*/
        [session setActive:YES error:&err];
        /*if (err) {
            NSLog(@"AVPlayer setSessionActive error: %@", err.localizedDescription);
        }*/
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
    if (_mtSpriteView) {
        for (MTSprite* sprite in _mtSpriteView.sprites) {
            [sprite onDestroy];
        }
        [_mtSpriteView.sprites removeAllObjects];
        if (reset) {
            [_mtSpriteView.sprites addObject:[[MTSprite alloc]initWithDevice:_mtSpriteView.device]];
        }
    } else if (_glSpriteView) {
        for (GLSprite* sprite in _glSpriteView.sprites) {
            [sprite onDestroy];
        }
        [_glSpriteView.sprites removeAllObjects];
        if (reset) {
            [_glSpriteView.sprites addObject:[GLSprite new]];
        }
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
                _textureFormat = [dict[@"texture"] isEqualToString:@"pvr"] ? TextureFormatPVR : TextureFormatPNG;
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
