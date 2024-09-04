//
//  ColorComponent.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColorComponent : NSObject <NSCopying>
@property (assign, nonatomic, readonly) float level;
@property (assign, nonatomic, readonly) UIColor *color;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithLevel:(float)level color:(UIColor *)color;
+ (ColorComponent *)componentByLevel:(float)level color:(UIColor *)color;
- (ColorComponent *)compnentByApplingLevel:(float)level;
- (ColorComponent *)compnentByApplingColor:(UIColor *)color;
@end

NS_ASSUME_NONNULL_END
