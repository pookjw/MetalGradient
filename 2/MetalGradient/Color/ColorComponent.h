//
//  ColorComponent.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColorComponent : NSObject <NSCopying>
@property (assign, nonatomic) float level;
@property (assign, nonatomic) simd_float3 color;
@end

NS_ASSUME_NONNULL_END
