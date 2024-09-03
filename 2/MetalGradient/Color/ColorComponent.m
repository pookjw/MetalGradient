//
//  ColorComponent.m
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import "ColorComponent.h"

@implementation ColorComponent

- (id)copyWithZone:(struct _NSZone *)zone {
    id copy = [[self class] new];
    
    if (copy) {
        __kindof ColorComponent *component = (ColorComponent *)copy;
        component->_level = _level;
        component->_color = _color;
    }
    
    return copy;
}

@end
