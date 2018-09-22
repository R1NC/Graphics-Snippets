//
//  MTSprite.m
//  MTSprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "MTSprite.h"
#import <Simd/Simd.h>
#import <Metal/Metal.h>
#import "MTUtil.h"
#import "MatrixUtil.h"

typedef struct {
    packed_float4 position;
    packed_float2 texCoords;
} VertexFormat;

const float VERTICES_DATA[] = {
    -1.0f, +1.0f, 0.0f, 1.0f,   0.0f, 0.0f, //TL
    +1.0f, +1.0f, 0.0f, 1.0f,   1.0f, 0.0f, //TR
    +1.0f, -1.0f, 0.0f, 1.0f,   1.0f, 1.0f, //BR
    -1.0f, -1.0f, 0.0f, 1.0f,   0.0f, 1.0f  //BL
};

typedef struct {
    matrix_float4x4 modelMatrix;
} Uniforms;

const uint16_t INDICES_DATA[] = {
    0, 1, 2,
    0, 3, 2
};

@interface MTSprite()
@property(nonatomic,strong) id<MTLDevice> device;
@property(nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic,strong) id<MTLRenderPipelineState> renderPipelineState;
@property(nonatomic,strong) id<MTLSamplerState> samplerState;
@property(nonatomic,strong) id<MTLBuffer> vertexBuffer, indexBuffer, uniformBuffer;
@property(nonatomic,assign) Uniforms uniforms;
@end

@implementation MTSprite

-(instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
        
        // Commands are submitted to a Metal device through its associated command queue.
        _commandQueue = [device newCommandQueue];
        
        [self prepareBuffersWithDevice:device];
        
        _renderPipelineState = [MTUtil renderPipelineWithDevice:device
                                                         vertexFuncName:@"vertex_func" fragmentFuncName:@"fragment_func"
                                                  vertexDescriptor:[self prepareVertexDescriptor]];
        
        _samplerState = [MTUtil samplerWithDevice:device];
    }
    return self;
}

-(void)renderDrawable:(id<CAMetalDrawable>)drawable inRect:(CGRect)rect {
    if (!_renderPipelineState || !drawable || !_texture) return;
    
    [self updateModelMatrixWithRect:rect];
    [self syncUniforms];
    [self renderDrawable:drawable];
}

-(void)onDestroy {
    //TODO
}

-(MTLVertexDescriptor*)prepareVertexDescriptor {
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].offset = sizeof(vector_float4);
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.layouts[0].stride = sizeof(VertexFormat);
    return vertexDescriptor;
}

-(void)prepareBuffersWithDevice:(id<MTLDevice>)device {
    _vertexBuffer = [device newBufferWithBytes:VERTICES_DATA length:sizeof(VERTICES_DATA) options:MTLResourceCPUCacheModeDefaultCache];
    _indexBuffer = [device newBufferWithBytes:INDICES_DATA length:sizeof(INDICES_DATA) options:MTLResourceCPUCacheModeDefaultCache];
    _uniformBuffer = [device newBufferWithLength:sizeof(Uniforms) options:MTLResourceCPUCacheModeDefaultCache];
}

-(void)updateModelMatrixWithRect:(CGRect)rect {
    matrix_float4x4 translateMatrix = [MatrixUtil makeTranslateX:self.transX y:self.transY z:0];
    matrix_float4x4 rotateMatrix = [MatrixUtil makeRotateX:0.0f y:0.0f z:-1.0 degree:self.angle];
    float baseScaleX = 1.0f, baseScaleY = 1.0f;
    if (_texture && _texture.width > 0 && _texture.height > 0) {
        float tw = _texture.width, th = _texture.height, vw = rect.size.width, vh = rect.size.height;
        if (tw * vh >= vw * th) {
            baseScaleY = vw * th / tw / vh;
        } else {
            baseScaleX = vh * tw / th / vw;
        }
    }
    matrix_float4x4 scaleMatrix = [MatrixUtil makeScaleX:self.scale * baseScaleX y:self.scale * baseScaleY z:1.0f];
    matrix_float4x4 modelMatrix = [MatrixUtil leftMultiplyMatrixA:translateMatrix matrixB:rotateMatrix];
    _uniforms.modelMatrix = [MatrixUtil leftMultiplyMatrixA:modelMatrix matrixB:scaleMatrix];
}

-(void)syncUniforms {
    void *bufferPointer = [_uniformBuffer contents];
    memcpy(bufferPointer, &_uniforms, sizeof(Uniforms));
}

-(void)renderDrawable:(id<CAMetalDrawable>)drawable {
    // CommandBuffer is a set of commands that will be executed and encoded in a compact way that the GPU understands.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // RenderPassDescriptor describes the actions Metal should take before and after rendering.(Like glClear & glClearColor)
    MTLRenderPassDescriptor *renderPassDescriptor = [MTUtil renderPassDescriptorWithTexture:drawable.texture];
    
    // RenderCommandEncoder is used to convert from draw calls into the language of the GPU.
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder setCullMode:MTLCullModeFront];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:_texture atIndex:0];
    [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];
    
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangleStrip indexCount:_indexBuffer.length/sizeof(uint16_t) indexType:MTLIndexTypeUInt16 indexBuffer:_indexBuffer indexBufferOffset:0];
    
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
