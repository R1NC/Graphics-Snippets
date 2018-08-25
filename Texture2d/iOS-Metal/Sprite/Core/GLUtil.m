//
//  GLUtil.m
//  Sprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "GLUtil.h"

@implementation GLUtil

+(matrix_float4x4)matrix2dWithRadius:(float)radians {
    float cos = cosf(radians);
    float sin = sinf(radians);
    matrix_float4x4 m = {
        .columns[0] = {  cos, sin, 0, 0 },
        .columns[1] = { -sin, cos, 0, 0 },
        .columns[2] = {    0,   0, 1, 0 },
        .columns[3] = {    0,   0, 0, 1 }
    };
    return m;
}

+(id<MTLRenderPipelineState>)renderPipelineWithDevice:(id<MTLDevice>)device vertexFuncName:(NSString*)vertexFuncName fragmentFuncName:(NSString*)fragmentFuncName {
    // Shader functions are compiled into the default library.
    id<MTLLibrary> library = [device newDefaultLibrary];
    // Shader functions are compiled when app builds, saving valuable time when app starts up.
    id<MTLFunction> vertexProgram = [library newFunctionWithName:vertexFuncName];
    id<MTLFunction> fragmentProgram = [library newFunctionWithName:fragmentFuncName];
    
    // Prepare render pipeline:
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    [renderPipelineDescriptor setVertexFunction:vertexProgram];
    [renderPipelineDescriptor setFragmentFunction:fragmentProgram];
    NSError* err = nil;
    id<MTLRenderPipelineState> renderPipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&err];
    if (err) {
        NSLog(@"Failed to create render pipeline: %@", err);
    }
    return renderPipelineState;
}

+(MTLRenderPassDescriptor*)renderPassDescriptorForTexture:(id<MTLTexture>)texture {
    MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    return renderPassDescriptor;
}

@end
