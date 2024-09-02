//
//  Renderer.m
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#import "Renderer.h"
#import <TargetConditionals.h>
#import "Grid.h"

RendererStyle * RendererStyleMethodAllValues(NSUInteger *count) {
    if (count != nullptr) {
        *count = 6;
    }
    
    static RendererStyle results[6] = {
        RendererStyle::Half,
        RendererStyle::FractStep,
        RendererStyle::Step,
        RendererStyle::Smoothstep,
        RendererStyle::SmoothstepMix,
        RendererStyle::Length
    };
    
    return results;
}

NSString * NSStringFromRenderDispatchMethod(RendererStyle method) {
    switch (method) {
        case RendererStyle::Half:
            return @"Half";
        case RendererStyle::FractStep:
            return @"FractStep";
        case RendererStyle::Step:
            return @"Step";
        case RendererStyle::Smoothstep:
            return @"Smoothstep";
        case RendererStyle::SmoothstepMix:
            return @"SmoothstepMix";
        case RendererStyle::Length:
            return @"Length";
        default:
            return nil;
    }
}

@interface Renderer () <MTKViewDelegate>
@property (retain, nonatomic, readonly) MTKView *view;
@property (retain, nonatomic, readonly) id<MTLDevice> device;
@property (retain, nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (retain, nonatomic, readonly) id<MTLRenderPipelineState> gridRenderPipelineState;
@property (retain, nonatomic, readonly) id<MTLRenderPipelineState> colorRenderPipelineState;
@property (retain, nonatomic, readonly) Grid *grid;
@property (retain, nonatomic, readonly) MTKMesh *colorMesh;
@property (assign, nonatomic) float colorPivot;
@property (assign, nonatomic) BOOL isColorPivotIncreasing;
@end

@implementation Renderer

- (instancetype)initWithView:(MTKView *)view {
    if (self = [super init]) {
        NSError * _Nullable error = nil;
        
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        id<MTLLibrary> library = [device newDefaultLibrary];
        
        id<MTLCommandQueue> commandQueue;
#if TARGET_OS_SIMULATOR
        commandQueue = [device newCommandQueue];
#else
        MTLLogStateDescriptor *logStateDescriptor = [MTLLogStateDescriptor new];
        logStateDescriptor.level = MTLLogLevelDebug;
        logStateDescriptor.bufferSize = 1024;
        id<MTLLogState> logState = [device newLogStateWithDescriptor:logStateDescriptor error:&error];
        [logStateDescriptor release];
        assert(error == nil);
        
        MTLCommandQueueDescriptor *commandQueueDescriptor = [MTLCommandQueueDescriptor new];
        commandQueueDescriptor.maxCommandBufferCount = 1;
        commandQueueDescriptor.logState = logState;
        [logState release];
        
        commandQueue = [device newCommandQueueWithDescriptor:commandQueueDescriptor];
        [commandQueueDescriptor release];
#endif
        
        view.device = device;
        view.delegate = self;
        view.depthStencilPixelFormat = MTLPixelFormatInvalid;
        view.clearColor = MTLClearColorMake(1.f, 1.f, 0.9f, 1.f);
        
        //
        
        NSURL *applicationURL = [[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask][0] URLByAppendingPathComponent:@"MetalGradient"];
        
        if (![NSFileManager.defaultManager fileExistsAtPath:applicationURL.path]) {
            [NSFileManager.defaultManager createDirectoryAtURL:applicationURL withIntermediateDirectories:YES attributes:nil error:&error];
            assert(error == nil);
        }
        
        NSURL *binaryArchiveURL = [applicationURL URLByAppendingPathComponent:@"shader.metallib"];
        
        //
        
        MTLFunctionDescriptor *gridVertexFunctionDescriptor = [MTLFunctionDescriptor new];
        gridVertexFunctionDescriptor.name = @"grid::vertex_main";
        
        if ([device supportsFunctionPointersFromRender]) {
            gridVertexFunctionDescriptor.options = MTLFunctionOptionCompileToBinary | MTLFunctionOptionFailOnBinaryArchiveMiss;
        }
        
        MTLFunctionDescriptor *gridFragmentFunctionDescriptor = [MTLFunctionDescriptor new];
        gridFragmentFunctionDescriptor.name = @"grid::fragment_main";
        
        if ([device supportsFunctionPointersFromRender]) {
            gridFragmentFunctionDescriptor.options = MTLFunctionOptionCompileToBinary | MTLFunctionOptionFailOnBinaryArchiveMiss;
        }
        
        id<MTLFunction> gridVertexFunction = [library newFunctionWithDescriptor:gridVertexFunctionDescriptor error:&error];
        [gridVertexFunctionDescriptor release];
        assert(error == nil);
        id<MTLFunction> gridFragmentFunction = [library newFunctionWithDescriptor:gridFragmentFunctionDescriptor error:&error];
        [gridFragmentFunctionDescriptor release];
        assert(error == nil);
        
        MDLVertexDescriptor *gridVertexDescriptor = [MDLVertexDescriptor new];
        gridVertexDescriptor.attributes[0].name = MDLVertexAttributePosition;
        gridVertexDescriptor.attributes[0].format = MDLVertexFormatFloat3;
        gridVertexDescriptor.attributes[0].offset = 0;
        gridVertexDescriptor.attributes[0].bufferIndex = 0;
        gridVertexDescriptor.layouts[0].stride = sizeof(simd_float3);
        
        MTLRenderPipelineDescriptor *gridRenderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        gridRenderPipelineDescriptor.vertexFunction = gridVertexFunction;
        [gridVertexFunction release];
        gridRenderPipelineDescriptor.fragmentFunction = gridFragmentFunction;
        [gridFragmentFunction release];
        gridRenderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        gridRenderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(gridVertexDescriptor);
        [gridVertexDescriptor release];
        gridRenderPipelineDescriptor.shaderValidation = MTLShaderValidationEnabled;
        
        //
        
        MTLFunctionDescriptor *colorVertexFunctionDescriptor = [MTLFunctionDescriptor new];
        colorVertexFunctionDescriptor.name = @"color::vertex_main";
        
        if ([device supportsFunctionPointersFromRender]) {
            colorVertexFunctionDescriptor.options = MTLFunctionOptionCompileToBinary | MTLFunctionOptionFailOnBinaryArchiveMiss;
        }
        
        MTLFunctionDescriptor *colorFragmentFunctionDescriptor = [MTLFunctionDescriptor new];
        colorFragmentFunctionDescriptor.name = @"color::fragment_main";
        
        if ([device supportsFunctionPointersFromRender]) {
            colorFragmentFunctionDescriptor.options = MTLFunctionOptionCompileToBinary | MTLFunctionOptionFailOnBinaryArchiveMiss;
        }
        
        id<MTLFunction> colorVertexFunction = [library newFunctionWithDescriptor:colorVertexFunctionDescriptor error:&error];
        [colorVertexFunctionDescriptor release];
        assert(error == nil);
        
        id<MTLFunction> colorFragmentFunction = [library newFunctionWithDescriptor:colorFragmentFunctionDescriptor error:&error];
        [colorFragmentFunctionDescriptor release];
        assert(error == nil);
        
        MDLVertexDescriptor *colorVertexDescriptor = [MDLVertexDescriptor new];
        colorVertexDescriptor.attributes[0].name = MDLVertexAttributePosition;
        colorVertexDescriptor.attributes[0].format = MDLVertexFormatFloat3;
        colorVertexDescriptor.attributes[0].offset = 0;
        colorVertexDescriptor.attributes[0].bufferIndex = 0;
        colorVertexDescriptor.layouts[0].stride = sizeof(simd_float3);
        
        MTLRenderPipelineDescriptor *colorRenderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        colorRenderPipelineDescriptor.vertexFunction = colorVertexFunction;
        [colorVertexFunction release];
        colorRenderPipelineDescriptor.fragmentFunction = colorFragmentFunction;
        [colorFragmentFunction release];
        colorRenderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        colorRenderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(colorVertexDescriptor);
        colorRenderPipelineDescriptor.shaderValidation = MTLShaderValidationEnabled;
        
        //
        
        if ([device supportsFunctionPointersFromRender]) {
            id<MTLBinaryArchive> binaryArchive;
            
            if ([NSFileManager.defaultManager fileExistsAtPath:binaryArchiveURL.path]) {
                MTLBinaryArchiveDescriptor *binaryArchiveDescriptor = [MTLBinaryArchiveDescriptor new];
                binaryArchiveDescriptor.url = binaryArchiveURL;
                
                binaryArchive = [device newBinaryArchiveWithDescriptor:binaryArchiveDescriptor error:&error];
                [binaryArchiveDescriptor release];
                assert(error == nil);
            } else {
                MTLBinaryArchiveDescriptor *binaryArchiveDescriptor = [MTLBinaryArchiveDescriptor new];
                binaryArchiveDescriptor.url = nil;
                
                binaryArchive = [device newBinaryArchiveWithDescriptor:binaryArchiveDescriptor error:&error];
                [binaryArchiveDescriptor release];
                assert(error == nil);
                
                [binaryArchive addRenderPipelineFunctionsWithDescriptor:gridRenderPipelineDescriptor error:&error];
                assert(error == nil);
                
                [binaryArchive addRenderPipelineFunctionsWithDescriptor:colorRenderPipelineDescriptor error:&error];
                assert(error == nil);
                
                [binaryArchive serializeToURL:binaryArchiveURL error:&error];
                assert(error == nil);
            }
            
            gridRenderPipelineDescriptor.binaryArchives = @[binaryArchive];
            [binaryArchive release];
        }
        
        id<MTLRenderPipelineState> gridRenderPipelineState = [device newRenderPipelineStateWithDescriptor:gridRenderPipelineDescriptor error:&error];
        [gridRenderPipelineDescriptor release];
        assert(error == nil);
        
        id<MTLRenderPipelineState> colorRenderPipelineState = [device newRenderPipelineStateWithDescriptor:colorRenderPipelineDescriptor error:&error];
        [colorRenderPipelineDescriptor release];
        assert(error == nil);
        
        //
        
        Grid *grid = [[Grid alloc] initWithDevice:device];
        
        MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
        
        MDLMesh *colorMDLMesh = [[MDLMesh alloc] initPlaneWithExtent:simd_make_float3(2.f, 2.f, 2.f)
                                                            segments:simd_make_uint2(1, 1)
                                                        geometryType:MDLGeometryTypeTriangles
                                                           allocator:allocator];
        [allocator release];
        
        colorMDLMesh.vertexDescriptor = colorVertexDescriptor;
        [colorVertexDescriptor release];
        
        MTKMesh *colorMesh = [[MTKMesh alloc] initWithMesh:colorMDLMesh device:device error:&error];
        [colorMDLMesh release];
        assert(error == nil);
        
        //
        
        [library release];
        
        _showGrid = YES;
        _style = RendererStyle::SmoothstepMix;
        _view = [view retain];
        _device = [device retain];
        _commandQueue = [commandQueue retain];
        _gridRenderPipelineState = [gridRenderPipelineState retain];
        _colorRenderPipelineState = [colorRenderPipelineState retain];
        _grid = [grid retain];
        _colorMesh = [colorMesh retain];
        
        [device release];
        [commandQueue release];
        [gridRenderPipelineState release];
        [colorRenderPipelineState release];
        [grid release];
        [colorMesh release];
    }
    
    return self;
}

- (void)dealloc {
    [_view release];
    [_device release];
    [_commandQueue release];
    [_gridRenderPipelineState release];
    [_colorRenderPipelineState release];
    [_grid release];
    [_colorMesh release];
    [super dealloc];
}

- (void)setShowGrid:(BOOL)showGrid {
    _showGrid = showGrid;
//    [self _drawInMTKView:_view];
}

- (void)setStyle:(RendererStyle)style {
    _style = style;
//    [self _drawInMTKView:_view];
}

- (void)_drawInMTKView:(MTKView *)view __attribute__((objc_direct)) {
    if (_colorPivot >= 1.f) {
        _isColorPivotIncreasing = NO;
    } else if (_colorPivot <= 0.f) {
        _isColorPivotIncreasing = YES;
    }
    
    if (_isColorPivotIncreasing) {
        _colorPivot += 0.01;
    } else {
        _colorPivot -= 0.01;
    }
    
    MTLCommandBufferDescriptor *commandBufferDescriptor = [MTLCommandBufferDescriptor new];
    commandBufferDescriptor.retainedReferences = NO;
    commandBufferDescriptor.errorOptions = MTLCommandBufferErrorOptionEncoderExecutionStatus;
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBufferWithDescriptor:commandBufferDescriptor];
    [commandBufferDescriptor release];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [view currentRenderPassDescriptor];
//    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
//    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    //
    
    [renderCommandEncoder setFragmentBytes:&_style length:sizeof(RendererStyle) atIndex:0];
    
    simd_uint2 size = simd_make_uint2(CGRectGetWidth(view.bounds) * view.traitCollection.displayScale, CGRectGetWidth(view.bounds) * view.traitCollection.displayScale);
    [renderCommandEncoder setFragmentBytes:&size length:sizeof(simd_double2) atIndex:1];
    
    [renderCommandEncoder setFragmentBytes:&_colorPivot length:sizeof(float) atIndex:2];
    
    [renderCommandEncoder setRenderPipelineState:_colorRenderPipelineState];
    
    [_colorMesh.vertexBuffers enumerateObjectsUsingBlock:^(MTKMeshBuffer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [renderCommandEncoder setVertexBuffer:obj.buffer offset:0 atIndex:idx];
    }];
    
    [renderCommandEncoder setTriangleFillMode:MTLTriangleFillModeFill];
    
    for (MTKSubmesh *submesh in _colorMesh.submeshes) {
        [renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                         indexCount:submesh.indexCount
                                          indexType:submesh.indexType
                                        indexBuffer:submesh.indexBuffer.buffer
                                  indexBufferOffset:submesh.indexBuffer.offset];
    }
    
    //
    
//    if (_showGrid) {
//        [renderCommandEncoder setTriangleFillMode:MTLTriangleFillModeLines];
//        [renderCommandEncoder setRenderPipelineState:_gridRenderPipelineState];
//        [renderCommandEncoder setVertexBuffer:_grid.vertexBuffer offset:0 atIndex:0];
//        [renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeLine indexCount:_grid.indices.size() indexType:MTLIndexTypeUInt16 indexBuffer:_grid.indexBuffer indexBufferOffset:0];
//    }
    
    //
    
    [renderCommandEncoder endEncoding];
    id<CAMetalDrawable> currentDrawable = [view currentDrawable];
    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
//    [self _drawInMTKView:view];
}

- (void)drawInMTKView:(MTKView *)view {
    [self _drawInMTKView:view];
}

@end
