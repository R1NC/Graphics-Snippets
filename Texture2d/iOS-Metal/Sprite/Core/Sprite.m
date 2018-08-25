//
//  Sprite.m
//  Sprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "Sprite.h"
#import <Simd/Simd.h>
#import "GLUtil.h"

const float VERTICES[] = {
    1.0, -1.0, 0.0, 1.0,     1.0, 0.0, 0.0, 1.0,
    -1.0, -1.0, 0.0, 1.0,     0.0, 1.0, 0.0, 1.0,
    -1.0,  1.0, 0.0, 1.0,     0.0, 0.0, 1.0, 1.0,
    
    1.0,  1.0, 0.0, 1.0,     1.0, 1.0, 0.0, 1.0,
    1.0, -1.0, 0.0, 1.0,     1.0, 0.0, 0.0, 1.0,
    -1.0,  1.0, 0.0, 1.0,     0.0, 0.0, 1.0, 1.0,
};

typedef struct {
    matrix_float4x4 rotation_matrix;
} Uniforms;

@interface Sprite()
@property(nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic,strong) id<MTLRenderPipelineState> renderPipelineState;
@property(nonatomic,strong) id<MTLBuffer> uniformBuffer, vertexBuffer;
@property(nonatomic,assign) Uniforms uniforms;
@end

@implementation Sprite

-(instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        // Commands are submitted to a Metal device through its associated command queue.
        _commandQueue = [device newCommandQueue];
        
        [self prepareBuffersWithDevice:device];
        
        _renderPipelineState = [GLUtil renderPipelineWithDevice:device vertexFuncName:@"vertex_func" fragmentFuncName:@"fragment_func"];
    }
    return self;
}

-(void)prepareBuffersWithDevice:(id<MTLDevice>)device {
    _vertexBuffer = [device newBufferWithBytes:VERTICES length:sizeof(VERTICES) options:MTLResourceOptionCPUCacheModeDefault];
    // Generate a buffer for holding the uniforms
    _uniformBuffer = [device newBufferWithLength:sizeof(Uniforms) options:MTLResourceOptionCPUCacheModeDefault];
}

-(void)renderDrawable:(id<CAMetalDrawable>)drawable inRect:(CGRect)rect {
    if (!_renderPipelineState || !drawable) return;
    
    [self updateUniforms];
    
    // CommandBuffer is a set of commands that will be executed and encoded in a compact way that the GPU understands.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // RenderPassDescriptor describes the actions Metal should take before and after rendering.(Like glClear & glClearColor)
    MTLRenderPassDescriptor *renderPassDescriptor = [GLUtil renderPassDescriptorForTexture:drawable.texture];
    
    // RenderCommandEncoder is used to convert from draw calls into the language of the GPU.
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:1];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

-(void)updateUniforms {
    _uniforms.rotation_matrix = [GLUtil matrix2dWithRadius:_angle];
    void *bufferPointer = [_uniformBuffer contents];
    memcpy(bufferPointer, &_uniforms, sizeof(Uniforms));
}

@end
