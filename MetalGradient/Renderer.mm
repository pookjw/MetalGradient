//
//  Renderer.m
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#import "Renderer.h"

@interface Renderer () <MTKViewDelegate>
@property (retain, nonatomic, readonly) MTKView *view;
@property (retain, nonatomic, readonly) id<MTLDevice> device;

@end

@implementation Renderer

- (instancetype)initWithView:(MTKView *)view {
    if (self = [super init]) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        
        view.device = device;
        view.delegate = self;
        view.depthStencilPixelFormat = MTLPixelFormatInvalid;
        view.clearColor = MTLClearColorMake(1.f, 1.f, 0.9f, 1.f);
        
        //
        
        NSError * _Nullable error = nil;
        
        NSURL *applicationURL = [[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask][0] URLByAppendingPathComponent:@"MetalGradient"];
        
        if (![NSFileManager.defaultManager fileExistsAtPath:applicationURL.path]) {
            [NSFileManager.defaultManager createDirectoryAtURL:applicationURL withIntermediateDirectories:YES attributes:nil error:&error];
            assert(error == nil);
        }
        
        NSURL *binaryArchiveURL = [applicationURL URLByAppendingPathComponent:@"shaderLib"];
        
        MTLBinaryArchiveDescriptor *binaryArchiveDescriptor = [MTLBinaryArchiveDescriptor new];
        binaryArchiveDescriptor.url = nil;
        
        id<MTLBinaryArchive> binaryArchive = [device newBinaryArchiveWithDescriptor:binaryArchiveDescriptor error:&error];
        [binaryArchiveDescriptor release];
        assert(error == nil);
        
        MTLFunctionDescriptor *vertexFunctionDescriptor = [MTLFunctionDescriptor new];
        vertexFunctionDescriptor.name = @"grid::vertex_main";
        vertexFunctionDescriptor.options = MTLFunctionOptionCompileToBinary;
        
        MTLFunctionDescriptor *fragmentFunctionDescriptor = [MTLFunctionDescriptor new];
        fragmentFunctionDescriptor.name = @"grid::fragment_main";
        vertexFunctionDescriptor.options = MTLFunctionOptionCompileToBinary;
        
        id<MTLLibrary> library = [device newDefaultLibrary];
        
        [binaryArchive addFunctionWithDescriptor:vertexFunctionDescriptor library:library error:&error];
        assert(error == nil);
        [binaryArchive addFunctionWithDescriptor:fragmentFunctionDescriptor library:library error:&error];
        assert(error == nil);
        
        [binaryArchive serializeToURL:binaryArchiveURL error:&error];
        assert(error == nil);
        
        [vertexFunctionDescriptor release];
        [fragmentFunctionDescriptor release];
        
        //
        
        _showGrid = YES;
        _device = [device retain];
        
        [device release];
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    
}

@end
