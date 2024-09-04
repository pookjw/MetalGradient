//
//  ColorGradientView.m
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import "ColorGradientView.h"
#import <MetalKit/MetalKit.h>
#include <array>
#include <vector>
#include <ranges>

@interface ColorGradientView ()
@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (retain, nonatomic, readonly) id<MTLDevice> device;
@property (retain, nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (retain, nonatomic, readonly) id<MTLRenderPipelineState> renderPipelineState;
@end

@implementation ColorGradientView

+ (Class)layerClass {
    return CAMetalLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CAMetalLayer *metalLayer = self.metalLayer;
        id<MTLDevice> device = metalLayer.preferredDevice;
        id<MTLLibrary> library = [device newDefaultLibrary];
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        NSError * _Nullable error = nil;
        
        //
        
        metalLayer.device = device;
        metalLayer.pixelFormat = MTLPixelFormatRGBA16Float; // P3
        metalLayer.wantsExtendedDynamicRangeContent = YES;
        
        //
        
        id<MTLFunction> vertexFunction = [library newFunctionWithName:@"metal_gradient::vertex_main"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"metal_gradient::fragment_main"];
        [library release];
        
        //
        
        MDLVertexDescriptor *vertexDescriptor = [MDLVertexDescriptor new];
        vertexDescriptor.attributes[0].name = MDLVertexAttributePosition;
        vertexDescriptor.attributes[0].format = MDLVertexFormatFloat2;
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        vertexDescriptor.layouts[0].stride = sizeof(simd_float2);
        
        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        renderPipelineDescriptor.vertexFunction = vertexFunction;
        [vertexFunction release];
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        [fragmentFunction release];
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIOWithError(vertexDescriptor, &error);
        [vertexDescriptor release];
        assert(error == nil);
        
        id<MTLRenderPipelineState> renderPipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
        [renderPipelineDescriptor release];
        assert(error == nil);
        
        //
        
        _device = [device retain];
        _commandQueue = [commandQueue retain];
        _renderPipelineState = [renderPipelineState retain];
        
        [commandQueue release];
        [renderPipelineState release];
    }
    
    return self;
}

- (void)dealloc {
    [_components release];
    [_device release];
    [_commandQueue release];
    [_renderPipelineState release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self drawWithComponents:self.components];
}

- (void)setComponents:(NSSet<ColorComponent *> *)components {
    [_components release];
    _components = [components copy];
    
    [self drawWithComponents:self.components];
}

- (CAMetalLayer *)metalLayer {
    return static_cast<CAMetalLayer *>(self.layer);
}

- (void)drawWithComponents:(NSSet<ColorComponent *> *)components {
    if (CGRectEqualToRect(self.metalLayer.frame, CGRectNull)) return;
    if (CGRectEqualToRect(self.metalLayer.frame, CGRectZero)) return;
    
    id<CAMetalDrawable> drawable = self.metalLayer.nextDrawable;
    
    if (drawable == nil) return;
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    MTLRenderPassColorAttachmentDescriptor *colorAttachmentDescriptor = [MTLRenderPassColorAttachmentDescriptor new];
    colorAttachmentDescriptor.texture = [drawable texture];
    colorAttachmentDescriptor.clearColor = MTLClearColorMake(0., 1., 1., 1.);
    colorAttachmentDescriptor.loadAction = MTLLoadActionClear;
    colorAttachmentDescriptor.storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0] = colorAttachmentDescriptor;
    [colorAttachmentDescriptor release];
    
    id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderPassDescriptor release];
    
    [renderCommandEncoder setRenderPipelineState:_renderPipelineState];
    [renderCommandEncoder setTriangleFillMode:MTLTriangleFillModeFill];
    
    //
    
    NSMutableArray<ColorComponent *> *sortedComponents = [[components.allObjects sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(ColorComponent *  _Nonnull obj1, ColorComponent * _Nonnull obj2) {
        if (obj1.level < obj2.level) {
            return NSOrderedAscending;
        } else if (obj1.level > obj2.level) {
            return NSOrderedDescending;
        } else {
            // TODO: Compare Color
            return NSOrderedSame;
        }
    }] mutableCopy];
    
    [sortedComponents addObject:[ColorComponent componentByLevel:1.f color:UIColor.blackColor]];
    
    float width = CGRectGetWidth(self.metalLayer.bounds);
    [renderCommandEncoder setFragmentBytes:&width length:sizeof(float) atIndex:2];
    
    __block float startX = -1.f;
    
    // TODO: Buffer를 setComponents:에서 만들기
    [sortedComponents enumerateObjectsUsingBlock:^(ColorComponent * _Nonnull component, NSUInteger idx, BOOL * _Nonnull stop) {
        ColorComponent * _Nullable prevComponent;
        if (idx == 0) {
            prevComponent = 0;
        } else {
            prevComponent = sortedComponents[idx - 1];
        }
        
        //
        
        std::vector<float> startColor(3);
        
        if (prevComponent == nil) {
            startColor[0] = 0.f;
            startColor[1] = 0.f;
            startColor[2] = 0.f;
        } else {
            UIColor *prevColor = prevComponent.color;
            std::array<CGFloat, 3> cg_startColor {};
            assert([prevColor getRed:cg_startColor.data() green:cg_startColor.data() + 1 blue:cg_startColor.data() + 2 alpha:NULL]);
            
            startColor = cg_startColor
            | std::views::transform([](CGFloat f) -> double { return f; })
            | std::ranges::to<std::vector<float>>();
        }
        
        [renderCommandEncoder setFragmentBytes:startColor.data() length:startColor.size() * sizeof(float) atIndex:3];
        
        //
        
        std::array<CGFloat, 3> cg_endColor {};
        assert([component.color getRed:cg_endColor.data() green:cg_endColor.data() + 1 blue:cg_endColor.data() + 2 alpha:NULL]);
        
        std::vector<float> endColor = cg_endColor
        | std::views::transform([](CGFloat f) -> double { return f; })
        | std::ranges::to<std::vector<float>>();
        
        
        [renderCommandEncoder setFragmentBytes:endColor.data() length:endColor.size() * sizeof(float) atIndex:4];
        
        //
        
        float width;
        if (prevComponent == nil) {
            width = 2.f * component.level;
        } else {
            width = 2.f * (component.level - prevComponent.level);
        }
        
        float endX = startX + width;
        
        std::array<simd_float2, 4> vertices {
            simd_make_float2(startX, 1.f),
            simd_make_float2(endX, 1.f),
            simd_make_float2(endX, -1.f),
            simd_make_float2(startX, -1.f)
        };
        
        [renderCommandEncoder setFragmentBytes:&startX length:sizeof(float) atIndex:0];
        [renderCommandEncoder setFragmentBytes:&endX length:sizeof(float) atIndex:1];
        
        startX += width;
        
        //
        
        constexpr std::array<std::uint16_t, 6> indices = {
            0, 1, 2, 0, 3, 2
        };
        
        //
        
        [renderCommandEncoder setVertexBytes:vertices.data() length:vertices.size() * sizeof(simd_float2) atIndex:0];
        
        id<MTLBuffer> indexBuffer = [_device newBufferWithBytes:indices.data() length:indices.size() * sizeof(std::uint16_t) options:MTLResourceHazardTrackingModeTracked];
        
        [renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:indices.size() indexType:MTLIndexTypeUInt16 indexBuffer:indexBuffer indexBufferOffset:0];
        
        [indexBuffer release];
    }];
    
    [sortedComponents release];
    
    //
    
    [renderCommandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
