//
//  Renderer.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/2/24.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject
@property (assign, nonatomic) BOOL showGrid;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithView:(MTKView *)view;
@end

NS_ASSUME_NONNULL_END
