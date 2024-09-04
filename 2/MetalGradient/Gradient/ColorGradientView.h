//
//  ColorGradientView.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import <UIKit/UIKit.h>
#import "ColorComponent.h"

NS_ASSUME_NONNULL_BEGIN

@interface ColorGradientView : UIView
@property (copy, nonatomic) NSSet<ColorComponent *> *components;
@end

NS_ASSUME_NONNULL_END
