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

typedef struct {
    float4x4 rotation_matrix;
} Uniforms;

typedef struct {
    float4 position;
    float4 color;
} VertexIn;

typedef struct {
    float4 position [[position]];
    half4  color;
} VertexOut;

vertex VertexOut vertex_func(device VertexIn *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = uniforms.rotation_matrix * vertices[vid].position;
    out.color = half4(vertices[vid].color);
    return out;
}

fragment half4 fragment_func(VertexOut in [[stage_in]]) {
    return in.color;
}
