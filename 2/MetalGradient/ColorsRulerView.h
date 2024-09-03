//
//  ColorsRulerView.h
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/3/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ColorsRulerView;
@protocol ColorsRulerViewDelegate <NSObject>
@end

@interface ColorsRulerView : UIView
@property (weak, nonatomic) id<ColorsRulerViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
