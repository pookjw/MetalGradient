//
//  ColorsRulerView.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/3/24.
//

#import <UIKit/UIKit.h>
#import "ColorComponent.h"

NS_ASSUME_NONNULL_BEGIN

@class ColorsRulerView;
@protocol ColorsRulerViewDelegate <NSObject>
- (void)colorsRulerView:(ColorsRulerView *)colorsRulerView didChangeColorComponents:(NSArray<ColorComponent *> *)colorComponents;
@end

@interface ColorsRulerView : UIView
@property (weak, nonatomic) id<ColorsRulerViewDelegate> delegate;
@property (copy, nonatomic) NSArray<ColorComponent *> *colorComponents;
@end

NS_ASSUME_NONNULL_END
