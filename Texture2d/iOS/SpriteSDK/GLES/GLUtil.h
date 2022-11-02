//
//  GLUtil.h
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface GLUtil : NSObject

+(GLuint)loadVertexGLSL:(NSString*)vertextGLSL fragmentGLSL:(NSString*)fragmentGLSL;

+(GLKTextureInfo*)loadTextureWithImagePath:(NSString*)imagePath;

//+(GLuint)textureWithImage:(UIImage*)image;

+(void)bindTexture:(GLKTextureInfo*)texture channel:(GLenum)channel location:(GLuint)location;

+(void)releaseTexture:(GLKTextureInfo*)texture;

+ (void)downloadImageFromTexture:(GLuint)texId size:(CGSize)size usePBO:(BOOL)usePBO completion:(void(^)(UIImage* img))completion;

+ (void)downloadPixelsFromTexture:(GLuint)texId size:(CGSize)size usePBO:(BOOL)usePBO completion:(void(^)(GLubyte *pixels))completion;

@end
