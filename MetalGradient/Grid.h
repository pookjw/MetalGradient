//
//  Grid.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#import <MetalKit/MetalKit.h>
#include <vector>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface Grid : NSObject
@property (assign, nonatomic, readonly) std::vector<simd_float3> vertices;
@property (assign, nonatomic, readonly) std::vector<std::uint16_t> indices;
@property (retain, nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (retain, nonatomic, readonly) id<MTLBuffer> indexBuffer;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
@end

NS_ASSUME_NONNULL_END
