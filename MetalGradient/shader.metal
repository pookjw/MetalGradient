//
//  shader.metal
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#include <metal_stdlib>
#import <simd/simd.h>
#include "RendererStyle.hpp"
using namespace metal;

namespace grid {
    struct VertexIn {
        float4 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
        return {
            .position = in.position
        };
    }
    
    fragment float4 fragment_main(VertexOut in [[stage_in]]) {
        return float4(0.f, 0.f, 0.f, 1.f);
    }
}

namespace color {
    struct VertexIn {
        float4 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
        matrix_float4x4 rotationX = {
            {1.f, 0.f, 0.f, 0.f},
            {0.f, cos(M_PI_2_F), sin(M_PI_2_F), 0.f},
            {0.f, -sin(M_PI_2_F), cos(M_PI_2_F), 0.f},
            {0.f, 0.f, 0.f, 1.f}
        };
        matrix_float4x4 rotationZ = {
            {cos(M_PI_2_F), sin(M_PI_2_F), 0.f, 0.f},
            {-sin(M_PI_2_F), cos(M_PI_2_F), 0.f, 0.f},
            {0.f, 0.f, 1.f, 0.f},
            {0.f, 0.f, 0.f, 1.f}
        };
        
        return {
            .position = float4((rotationX * rotationZ * in.position).xy, 0.f, 1.f)
        };
    }
    
    fragment float4 fragment_main(VertexOut in [[stage_in]],
                                  constant RendererStyle &style [[buffer(0)]],
                                  constant simd_uint2 &size [[buffer(1)]],
                                  constant float &colorPivot [[buffer(2)]]) {
        float3 color1 = float3(1 - colorPivot * 0.75f, colorPivot * 0.8f, 1 - colorPivot * 0.5f);
        float3 color2 = float3(1.f - colorPivot * 0.5f, 1.f - colorPivot, colorPivot * 0.75f);
        float3 color3 = float3(colorPivot * 0.5f, colorPivot * 0.85f, 1.f - colorPivot);
        
        switch (style) {
            case RendererStyle::Half: {
                float color = step(size.x * 0.5, in.position.x);
                
                return float4(color, color, color, 1.f);
            }
            case RendererStyle::SmoothstepMix: {
                float result = smoothstep(0, size.x, in.position.x);
                
                // x + (y - x) * 0.6f
                float3 color = mix(color1, color2, result);
                
                return float4(color, 1.f);
            }
            default:
                return float4(1.f, 1.f, 1.f, 1.f);
        }
    }
}
