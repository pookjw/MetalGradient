//
//  Grid.m
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#import "Grid.h"
#include <ranges>

@implementation Grid

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        const std::vector<simd_float3> verticalVertices = std::views::iota(0, 38)
        | std::views::transform([](std::uint8_t num) -> simd_float3 {
            return simd_make_float3(-0.9f + (num / 2) * 0.1f,
                                    (num % 2 == 0) ? 1.f : -1.f,
                                    0.f);
        })
        | std::ranges::to<std::vector<simd_float3>>();
        
        const std::vector<simd_float3> horizontalVertices = std::views::iota(0, 38)
        | std::views::transform([](std::uint8_t num) -> simd_float3 {
            return simd_make_float3((num % 2 == 0) ? 1.f : -1.f,
                                    0.9f - (num / 2) * 0.1f,
                                    0.f);
        })
        | std::ranges::to<std::vector<simd_float3>>();
        
        _vertices = std::vector<simd_float3>();
        _vertices.reserve(verticalVertices.size() + horizontalVertices.size());
        _vertices.insert(_vertices.cend(), verticalVertices.cbegin(), verticalVertices.cend());
        _vertices.insert(_vertices.cend(), horizontalVertices.cbegin(), horizontalVertices.cend());
        
        id<MTLBuffer> vertexBuffer = [device newBufferWithBytes:_vertices.data() length:sizeof(simd_float3) * _vertices.size() options:MTLResourceHazardTrackingModeTracked];
        
        //
        
        _indices = std::views::iota(0, 77) | std::ranges::to<std::vector<std::uint16_t>>();
        
        id<MTLBuffer> indexBuffer = [device newBufferWithBytes:_indices.data() length:sizeof(std::uint16_t) * _indices.size() options:MTLResourceHazardTrackingModeTracked];
        
        //
        
        _vertexBuffer = [vertexBuffer retain];
        _indexBuffer = [indexBuffer retain];
        
        [vertexBuffer release];
        [indexBuffer release];
    }
    
    return self;
}

- (void)dealloc {
    [_vertexBuffer release];
    [_indexBuffer release];
    [super dealloc];
}

@end
