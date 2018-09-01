//
//  MTUtil.h
//  MTSprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Simd/Simd.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MTUtil : NSObject

+(id<MTLRenderPipelineState>)renderPipelineWithDevice:(id<MTLDevice>)device
                                            vertexFuncName:(NSString*)vertexFuncName fragmentFuncName:(NSString*)fragmentFuncName
                                     vertexDescriptor:(MTLVertexDescriptor*)vertexDescriptor;

+(MTLRenderPassDescriptor*)renderPassDescriptorWithTexture:(id<MTLTexture>)texture;

+(id<MTLSamplerState>)samplerWithDevice:(id<MTLDevice>)device;

+(id<MTLTexture>)loadTextureWithImagePath:(NSString*)imagePath device:(id<MTLDevice>)device;

@end
