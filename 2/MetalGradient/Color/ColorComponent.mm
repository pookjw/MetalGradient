//
//  ColorComponent.m
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import "ColorComponent.h"
#include <functional>

@implementation ColorComponent

- (instancetype)initWithLevel:(float)level color:(UIColor *)color {
    if (self = [super init]) {
        _level = level;
        _color = [color retain];
    }
    
    return self;
}

+ (ColorComponent *)componentByLevel:(float)level color:(UIColor *)color {
    return [[[ColorComponent alloc] initWithLevel:level color:color] autorelease];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    id copy = [[self class] new];
    
    if (copy) {
        auto component = static_cast<__kindof ColorComponent *>(copy);
        component->_level = _level;
        component->_color = [_color copyWithZone:zone];
    }
    
    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if ([super isEqual:other]) {
        return YES;
    } else {
        auto component = static_cast<__kindof ColorComponent *>(other);
        return _level == component->_level && [_color isEqual:component->_color];
    }
}

- (NSUInteger)hash {
    return std::hash<float>{}(_level) ^ _color.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, level: %lf, color: %@", [super description], _level, _color];
}

- (ColorComponent *)compnentByApplingLevel:(float)level {
    return [[[ColorComponent alloc] initWithLevel:level color:_color] autorelease];
}

- (ColorComponent *)compnentByApplingColor:(UIColor *)color {
    return [[[ColorComponent alloc] initWithLevel:_level color:color] autorelease];
}

@end
