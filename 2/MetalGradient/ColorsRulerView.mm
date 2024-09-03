//
//  ColorsRulerView.mm
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/3/24.
//

#import "ColorsRulerView.h"

@implementation ColorsRulerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self ColorsRulerView_commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self ColorsRulerView_commonInit];
    }
    
    return self;
}

- (void)ColorsRulerView_commonInit {
    self.backgroundColor = UIColor.systemCyanColor;
}

@end
