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

@end
