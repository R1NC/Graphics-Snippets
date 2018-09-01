//
//  MTUtil.m
//  MTSprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "MTUtil.h"

@implementation MTUtil

+(id<MTLRenderPipelineState>)renderPipelineWithDevice:(id<MTLDevice>)device
                                            vertexFuncName:(NSString*)vertexFuncName fragmentFuncName:(NSString*)fragmentFuncName
                                     vertexDescriptor:(MTLVertexDescriptor *)vertexDescriptor {
    NSError* err = nil;
    // Shader functions are compiled into the default library.
    id<MTLLibrary> library = [device newDefaultLibrary];
    // Shader functions are compiled when app builds, saving valuable time when app starts up.
    id<MTLFunction> vertexProgram = [library newFunctionWithName:vertexFuncName];
    id<MTLFunction> fragmentProgram = [library newFunctionWithName:fragmentFuncName];
    if (vertexProgram == nil || fragmentProgram == nil) return nil;
    
    // Prepare render pipeline:
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    renderPipelineDescriptor.sampleCount = 1;
    [renderPipelineDescriptor setVertexDescriptor:vertexDescriptor];
    [renderPipelineDescriptor setVertexFunction:vertexProgram];
    [renderPipelineDescriptor setFragmentFunction:fragmentProgram];
    
    id<MTLRenderPipelineState> renderPipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&err];
    if (err) {
        NSLog(@"Failed to create renderPipelineState: %@", err);
        return nil;
    }
    return renderPipelineState;
}

+(id<MTLSamplerState>)samplerWithDevice:(id<MTLDevice>)device {
    MTLSamplerDescriptor* samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.mipFilter = MTLSamplerMipFilterNearest;
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.rAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.normalizedCoordinates = true;
    samplerDescriptor.lodMaxClamp = FLT_MAX;
    samplerDescriptor.lodMinClamp = 0;
    samplerDescriptor.maxAnisotropy = 1;
    return [device newSamplerStateWithDescriptor:samplerDescriptor];
}

+(MTLRenderPassDescriptor*)renderPassDescriptorWithTexture:(id<MTLTexture>)texture {
    MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    return renderPassDescriptor;
}

+(id<MTLTexture>)loadTextureWithImagePath:(NSString*)imagePath device:(id<MTLDevice>)device {
    if (imagePath) {
        MTKTextureLoader* loader = [[MTKTextureLoader alloc]initWithDevice:device];
        NSError* err = nil;
        id<MTLTexture> texture = [loader newTextureWithContentsOfURL:[NSURL fileURLWithPath:imagePath] options:@{MTKTextureLoaderOptionSRGB: @NO} error:&err];
        if (err) {
            NSLog(@"Failed to load texture %@", err);
        }
        return texture;
    }
    return nil;
}

@end
