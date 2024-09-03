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
        switch (style) {
            case RendererStyle::Half: {
                float color = step(size.x * 0.5, in.position.x);
                
                return float4(color, color, color, 1.f);
            }
            case RendererStyle::FractStep: {
                uint checks = 8;
                
                // 좌표를 0과 1 사이로 변환
                float2 uv = in.position.xy / size.x;
                
                // fract(x) = x - floor(x)
                // fract(-0.4) = 0.6
                // fract(3.4) = 0.4
                uv = fract(uv * checks * 0.5f) - 0.5f;
                
                /*
                 -0.5      0.0        0.5
                  ---------------------  -0.5
                 |          |          |
                 |          |          |
                 |    B     |     W    |
                 |          |          |
                  ---------------------
                  ---------------------  0.0
                 |          |          |
                 |          |          |
                 |    W     |     B    |
                 |          |          |
                  ---------------------  0.5
                 */
                
                // X와 Y를 곱한 값이 0보다 크면 0, 작으면 1
                float3 color = step(uv.x * uv.y, 0.f);
                
                return float4(color, 1.f);
            }
            case RendererStyle::Step: {
                float center = 0.5f;
                float radius = 0.2f;
                
                // 좌표를 -0.5 부터 0.5 사이의 값으로 변경
                float2 uv = (in.position.xy / size.x) - center;
                
                // 원점 부터의 길이가 radius 보다 작으면 1, 크면 0
                float3 color = step(length(uv), radius);
                
                return float4(color, 1.f);
            }
            case RendererStyle::Smoothstep: {
                /*
                 https://en.wikipedia.org/wiki/Smoothstep
                 
                 float x, y, z;
                 
                 float w = min(y, max(x, z)) / y;
                 
                 if (w <= 0) {
                    return 0.f;
                 } else if (w < 1.f) {
                    return w * w * (3.f - 2.f * w);
                 } else {
                    return 1.f;
                 }
                 */
                float color = smoothstep(0.f, size.x, in.position.x);
                
                return float4(color, color, color, 1.f);
                
//                float color;
//                
//                float w = min(float(size.x), max(0.f, in.position.x)) / size.x;
//                
//                if (w <= 0.f) {
//                    color = 0.f;
//                } else if (w < 1.f) {
//                    color = w * w * (3.f - 2.f * w);
//                } else {
//                    color = 1.f;
//                }
//                return float4(color, color, color, 1.f);
            }
            case RendererStyle::SmoothstepMix: {
                float result = smoothstep(0, size.x, in.position.x);
                
                float3 color1 = float3(1 - colorPivot * 0.75f, colorPivot * 0.8f, 1 - colorPivot * 0.5f);
                float3 color2 = float3(1.f - colorPivot * 0.5f, 1.f - colorPivot, colorPivot * 0.75f);
                
                // x + (y - x) * 0.6f
                float3 color = mix(color1, color2, result);
                
                return float4(color, 1.f);
            }
            case RendererStyle::Length: {
                float3 color;
                float length = metal::length(in.position.xyz);
                
                color.x = in.position.x / length;
                color.y = in.position.y / length;
                color.z = in.position.z / length; // 0.f
                
                return float4(color, 1.f);
            }
            default:
                return float4(1.f, 1.f, 1.f, 1.f);
        }
    }
}
