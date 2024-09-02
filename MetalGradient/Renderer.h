//
//  Renderer.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#import <MetalKit/MetalKit.h>
#include "RendererStyle.hpp"

NS_ASSUME_NONNULL_BEGIN

extern RendererStyle *RendererStyleMethodAllValues(NSUInteger *count);
extern NSString * NSStringFromRenderDispatchMethod(RendererStyle method);

@interface Renderer : NSObject
@property (assign, nonatomic) BOOL showGrid;
@property (assign, nonatomic) RendererStyle style;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithView:(MTKView *)view;
@end

NS_ASSUME_NONNULL_END
