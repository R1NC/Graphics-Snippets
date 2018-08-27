//
//  Sprite.metal
//  Sprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

// Define the data type that corresponds to the layout of the vertex data.
typedef struct {
    packed_float3 position;
    packed_float2 texCoord;
} VertexIn;

// Define the data type that will be passed from vertex shader to fragment shader.
typedef struct {
    float4 position [[position]];
    float2 texCoord;
} VertexOut;

// Uniforms
typedef struct {
    float4x4 modelMatrix;
    float4x4 cameraMatrix;
    float4x4 projectionMatrix;
} Uniforms;

// Vertex shader function
vertex VertexOut vertex_func(const device VertexIn* vertices [[buffer(0)]],
                             const device Uniforms& uniforms [[buffer(1)]],
                             unsigned int index [[vertex_id]]) {
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));
    
    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    
    //VertexIn in = vertices[index];
    VertexOut out;
    //out.position = uniforms.projectionMatrix * uniforms.cameraMatrix * uniforms.modelMatrix * float4(in.position, 1);
    out.position = renderedCoordinates[index];
    //out.texCoord = in.texCoord;
    out.texCoord = textureCoordinates[index];
    return out;
}

// Fragment shader function
fragment float4 fragment_func(VertexOut in [[stage_in]],
                             texture2d<float> tex2d [[texture(0)]],
                             sampler sampler2d [[sampler(0)]]) {
    return tex2d.sample(sampler2d, in.texCoord);
}
