//
//  shader.metal
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

namespace grid {
    vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
        return {
            .position = in.position
        };
    }
    
    fragment float4 fragment_main(VertexOut in [[stage_in]]) {
        return float4(0.f, 0.f, 0.f, 1.f);
    }
}
