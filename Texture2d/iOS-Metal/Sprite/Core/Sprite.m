//
//  Sprite.m
//  Sprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "Sprite.h"
#import <Simd/Simd.h>
#import <Metal/Metal.h>
#import "MetalUtil.h"

typedef struct {
    packed_float4 position;
    packed_float2 texCoords;
} VertexFormat;

const float VERTICES[] = {
    -1.0f, +1.0f, 0.0f, 1.0f,   0.0f, 0.0f, //TL
    +1.0f, +1.0f, 0.0f, 1.0f,   1.0f, 0.0f, //TR
    +1.0f, -1.0f, 0.0f, 1.0f,   1.0f, 1.0f, //BR
    -1.0f, -1.0f, 0.0f, 1.0f,   0.0f, 1.0f  //BL
};

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 cameraMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

const uint16_t INDICES[] = {
    0, 1, 2,
    0, 3, 2
};

// Position the eye behind the origin
const float CAMERA_EYE_X = 0.0f;
const float CAMERA_EYE_Y = 0.0f;
const float CAMERA_EYE_Z = 3.0f;

// We are looking toward the distance
const float CAMERA_CENTER_X = 0.0f;
const float CAMERA_CENTER_Y = 0.0f;
const float CAMERA_CENTER_Z = 0.0f;

// This is where our head would be pointing were we holding the camera.
const float CAMERA_UP_X = 0.0f;
const float CAMERA_UP_Y = 1.0f;
const float CAMERA_UP_Z = 0.0f;

@interface Sprite()
@property(nonatomic,strong) id<MTLDevice> device;
@property(nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic,strong) id<MTLRenderPipelineState> renderPipelineState;
@property(nonatomic,strong) id<MTLSamplerState> samplerState;
@property(nonatomic,strong) id<MTLBuffer> vertexBuffer, indexBuffer, uniformBuffer;
@property(nonatomic,strong) id<MTLTexture> texture;
@property(nonatomic,assign) Uniforms uniforms;
@end

@implementation Sprite

-(instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _transX = 0.0f;
        _transY = 0.0f;
        _angle = 0.0f;
        _scale = 1.0f;
        
        _device = device;
        
        _textureImagePath = [[NSBundle mainBundle] pathForResource:@"bomb" ofType:@"png"];
        
        // Commands are submitted to a Metal device through its associated command queue.
        _commandQueue = [device newCommandQueue];
        
        [self prepareBuffersWithDevice:device];
        
        _renderPipelineState = [MetalUtil renderPipelineWithDevice:device vertexFuncName:@"vertex_func" fragmentFuncName:@"fragment_func" vertexDescriptor:[self prepareVertexDescriptor]];
        
        _samplerState = [MetalUtil samplerWithDevice:device];
        
        //[self setCameraMatrix];
    }
    return self;
}

-(void)renderDrawable:(id<CAMetalDrawable>)drawable inRect:(CGRect)rect {
    if (!_renderPipelineState || !drawable || !_textureImagePath) return;
    
    _texture = [MetalUtil loadTextureWithImagePath:_textureImagePath device:_device];
    
    if (_texture) {
        //[self updateProjectionMatrixWithRect:rect];
        [self updateModelMatrixWithRect:rect];
        [self updateUniforms];
        [self renderDrawable:drawable];
    }
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
    _vertexBuffer = [device newBufferWithBytes:VERTICES length:sizeof(VERTICES) options:MTLResourceOptionCPUCacheModeDefault];
    _indexBuffer = [device newBufferWithBytes:INDICES length:sizeof(INDICES) options:MTLResourceOptionCPUCacheModeDefault];
    _uniformBuffer = [device newBufferWithLength:sizeof(Uniforms) options:MTLResourceOptionCPUCacheModeDefault];
}

//-(void)setCameraMatrix {
//    _uniforms.cameraMatrix = [MetalUtil matrixf44WithGLKMatrix4:GLKMatrix4MakeLookAt(CAMERA_EYE_X, CAMERA_EYE_Y, CAMERA_EYE_Z, CAMERA_CENTER_X, CAMERA_CENTER_Y, CAMERA_CENTER_Z, CAMERA_UP_X, CAMERA_UP_Y, CAMERA_UP_Z)];
//    _uniforms.cameraMatrix = [MetalUtil matrixf44WithGLKMatrix4:GLKMatrix4Identity];
//}
//
//-(void)updateProjectionMatrixWithRect:(CGRect)rect {
//    float ratio = rect.size.width / rect.size.height;
//    float left = -ratio;
//    float right = ratio;
//    float bottom = -1.0f;
//    float top = 1.0f;
//    float nearZ = 3.0f;
//    float farZ = 7.0f;
//    _uniforms.projectionMatrix = [MetalUtil matrixf44WithGLKMatrix4:GLKMatrix4MakeFrustum(left, right, bottom, top, nearZ, farZ)];
//    _uniforms.projectionMatrix = [MetalUtil matrixf44WithGLKMatrix4:GLKMatrix4Identity];
//}

-(void)updateModelMatrixWithRect:(CGRect)rect {
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(_transX, _transY, 0.0);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(_angle) , 0.0, 0.0, -1.0);
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(_scale, _scale, 1.0);
    GLKMatrix4 modelMatrix = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
    modelMatrix = GLKMatrix4Multiply(modelMatrix, scaleMatrix);
    _uniforms.modelMatrix = [MetalUtil matrixf44WithGLKMatrix4:modelMatrix];
}

-(void)updateUniforms {
    void *bufferPointer = [_uniformBuffer contents];
    memcpy(bufferPointer, &_uniforms, sizeof(Uniforms));
}

-(void)renderDrawable:(id<CAMetalDrawable>)drawable {
    // CommandBuffer is a set of commands that will be executed and encoded in a compact way that the GPU understands.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // RenderPassDescriptor describes the actions Metal should take before and after rendering.(Like glClear & glClearColor)
    MTLRenderPassDescriptor *renderPassDescriptor = [MetalUtil renderPassDescriptorWithTexture:drawable.texture];
    
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
