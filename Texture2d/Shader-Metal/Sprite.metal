//
//  Sprite.metal
//  Sprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Define the data type that corresponds to the layout of the vertex data.
typedef struct {
    float4 position;
    float4 color;
} In;

// Define the data type that will be passed from vertex shader to fragment shader.
typedef struct {
    float4 position [[position]];
    half4  color;
} Out;

//
typedef struct {
    float4x4 trans_matrix;
} Uniforms;

// Vertex shader function
vertex Out vertex_func(device In *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint index [[vertex_id]]) {
    Out out;
    out.position = uniforms.trans_matrix * vertices[index].position;
    out.color = half4(vertices[index].color);
    return out;
}

// Fragment shader function
fragment half4 fragment_func(Out in [[stage_in]]) {
    return in.color;
}
