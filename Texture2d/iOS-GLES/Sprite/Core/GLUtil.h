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

+(GLKTextureInfo*)textureInfoWithImageFilePath:(NSString*)imageFilePath;

//+(GLuint)textureWithImage:(UIImage*)image;

+(void)bindTextureInfo:(GLKTextureInfo*)textureInfo channel:(GLenum)channel location:(GLuint)location;

+(void)releaseTextureInfo:(GLKTextureInfo*)textureInfo;

@end
