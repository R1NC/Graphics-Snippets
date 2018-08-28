//
//  GLUtil.m
//  Sprite
//
//  Created by Rinc Liu on 7/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "GLUtil.h"

@implementation GLUtil

+(GLKTextureInfo*)loadTextureWithImagePath:(NSString*)imagePath {
    if (imagePath) {
        NSError *error;
        NSLog(@"GL Error = %u", glGetError());//Required to fix a system bug. Or GLKTextureLoader may return nil.
        GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:imagePath options:nil error:&error];
        if (!error) {
            return textureInfo;
        }
    }
    return nil;
}

+(void)bindTexture:(GLKTextureInfo*)texture channel:(GLenum)channel location:(GLuint)location {
    if (texture) {
        glEnable(texture.target);
        glActiveTexture(channel);
        glBindTexture(texture.target, texture.name);
        GLuint textureID = (GLuint)(channel - GL_TEXTURE0);
        glUniform1i(location, textureID);
    }
}

+(void)releaseTexture:(GLKTextureInfo*)texture {
    if (texture) {
        GLuint name = texture.name;
        glDeleteTextures(1, &name);
        texture = nil;
    }
}

/*+(GLuint)textureWithImage:(UIImage*)image {
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        return -1;
    }
    
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    GLubyte *data = (GLubyte*)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //CGContextTranslateCTM(context, 0, height);
    //CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    
    glEnable(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(data);
    
    return texture;
}*/

+(GLuint)loadVertexGLSL:(NSString*)vertextGLSL fragmentGLSL:(NSString*)fragmentGLSL {
    GLuint vertexShader = [self compileGLSL:vertextGLSL type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileGLSL:fragmentGLSL type:GL_FRAGMENT_SHADER];
    if (vertexShader > 0 && fragmentShader > 0) {
        GLuint program = glCreateProgram();
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragmentShader);
        glLinkProgram(program);
        GLint linkResult;
        glGetProgramiv(program, GL_LINK_STATUS, &linkResult);
        if (linkResult == GL_FALSE) {
            GLchar messages[256];
            glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
            NSLog(@"%@", [NSString stringWithUTF8String:messages]);
            return -2;
        }
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);
        return program;
    }
    return -1;
}

+(GLuint)compileGLSL:(NSString*)glsl type:(GLenum)type {
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:glsl ofType:@"glsl"];
    NSError* error;
    NSString* shaderContent = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderContent) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        return -1;
    }
    GLuint shader = glCreateShader(type);
    const char* shaderStringUTF8 = [shaderContent UTF8String];
    int shaderStringLength = [shaderContent length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shader);
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSLog(@"%@", [NSString stringWithUTF8String:messages]);
        return -2;
    }
    return shader;
}

@end
