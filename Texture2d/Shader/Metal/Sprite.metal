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
struct VertexIn {
    packed_float4 position;
    packed_float2 texCoords;
};

// Define the data type that will be passed from vertex shader to fragment shader.
struct VertexOut {
    float4 position [[position]];
    float2 texCoords [[user(tex_coords)]];
};

// Uniforms
struct Uniforms {
    float4x4 modelMatrix;
};

// Vertex shader function
vertex VertexOut vertex_func(constant VertexIn* vertices [[buffer(0)]],
                             constant Uniforms& uniforms [[buffer(1)]],
                             ushort index [[vertex_id]]) {
    VertexIn in = vertices[index];
    VertexOut out;
    out.position = uniforms.modelMatrix * float4(in.position);
    out.texCoords = in.texCoords;
    return out;
}

// Fragment shader function
fragment float4 fragment_func(VertexOut in [[stage_in]],
                              texture2d<float/*, access::sample*/> texture [[texture(0)]],
                              sampler texSampler [[sampler(0)]]) {
    return texture.sample(texSampler, in.texCoords);
}
