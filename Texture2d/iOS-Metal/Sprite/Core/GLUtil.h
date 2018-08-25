//
//  GLUtil.h
//  Sprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Simd/Simd.h>
#import <Metal/Metal.h>

@interface GLUtil : NSObject

+(matrix_float4x4)matrix2dWithRadius:(float)radians;

+(id<MTLRenderPipelineState>)prepareRenderPipelineWithDevice:(id<MTLDevice>)device vertexFuncName:(NSString*)vertexFuncName fragmentFuncName:(NSString*)fragmentFuncName;

+(MTLRenderPassDescriptor*)renderPassDescriptorForTexture:(id<MTLTexture>)texture;

@end
