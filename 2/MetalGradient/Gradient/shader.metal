//
//  shader.metal
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/4/24.
//

#include <metal_stdlib>
using namespace metal;

namespace metal_gradient {
    struct VertexIn {
        float2 position [[attribute(0)]];
    };
    
    struct VertexOut {
        float4 position [[position]];
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                                 uint vertexID [[vertex_id]]) {
        return {
            .position = float4(in.position, 0.f, 1.f),
        };
    }
    
    fragment float4 fragment_main(VertexOut in [[stage_in]],
                                  constant float &startX [[buffer(0)]],
                                  constant float &endX [[buffer(1)]],
                                  constant float &width [[buffer(2)]],
                                  constant packed_float3 &startColor [[buffer(3)]],
                                  constant packed_float3 &endColor [[buffer(4)]]) {
//        float result = smoothstep(0., (endX - startX) * width, in.position.x - (startX + 1.f) * width);
//        float3 color = mix(startColor, endColor, result);
        float percentage = (in.position.x - (startX + 1.f) * width * 0.5f) / ((endX - startX) * width * 0.5f);
        float3 color = float3(startColor.x + (endColor.x - startColor.x) * percentage,
                              startColor.y + (endColor.y - startColor.y) * percentage,
                              startColor.z + (endColor.z - startColor.z) * percentage);
        return float4(color, 1.f);
//        return float4(in.endColor, 1.f);
    }
}
