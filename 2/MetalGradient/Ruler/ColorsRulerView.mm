//
//  ColorsRulerView.mm
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/3/24.
//

#import "ColorsRulerView.h"
#import <objc/message.h>
#import <objc/runtime.h>

@interface ColorsRulerView () <UIColorPickerViewControllerDelegate, UIContextMenuInteractionDelegate>
@property (class, nonatomic, readonly) void *componentKey;
@property (retain, nonatomic, readonly) UIButton *addButton;
@property (copy, nonatomic) NSDictionary<ColorComponent *, __kindof UIView *> *colorViewsByComponent;
@property (retain, nonatomic, nullable) __kindof UIView *draggingColorView;
@property (assign, nonatomic) CGFloat draggingColorViewInitialPositionX;
@end

@implementation ColorsRulerView
@synthesize addButton = _addButton;

+ (void *)componentKey {
    static void *componentKey = &componentKey;
    return componentKey;
}

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

- (void)dealloc {
    [_addButton release];
    [_colorViewsByComponent release];
    [_draggingColorView release];
    [super dealloc];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(200., CGRectGetHeight(self.addButton.frame) + 100.);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateColorViewFrames];
}

- (void)ColorsRulerView_commonInit {
//    self.backgroundColor = UIColor.grayColor;
    
    _colorViewsByComponent = [NSDictionary new];
    
    //
    
    UIButton *addButton = self.addButton;
    addButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:addButton];
    [NSLayoutConstraint activateConstraints:@[
        [addButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [addButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [addButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
    
    //
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerPanGestureRecognizer:)];
    [self addGestureRecognizer:panGestureRecognizer];
    [panGestureRecognizer release];
}

- (NSSet<ColorComponent *> *)components {
    return [NSSet setWithArray:self.colorViewsByComponent.allKeys];
}

- (void)setComponents:(NSSet<ColorComponent *> *)components {
    NSMutableDictionary<ColorComponent *, __kindof UIView *> *newColorViewsByComponent = [[NSMutableDictionary alloc] initWithCapacity:components.count];
    
    [self.colorViewsByComponent enumerateKeysAndObjectsUsingBlock:^(ColorComponent * _Nonnull component, __kindof UIView * _Nonnull colorView, BOOL * _Nonnull stop) {
        if ([components containsObject:component]) {
            newColorViewsByComponent[component] = colorView;
        } else {
            [colorView removeFromSuperview];
        }
    }];
    
    for (ColorComponent *component in components) {
        if ([newColorViewsByComponent.allKeys containsObject:component]) continue;
        
        __kindof UIView *colorview = [self makeColorViewWithCompoent:component];
        [self addSubview:colorview];
        newColorViewsByComponent[component] = colorview;
    }
    
    self.colorViewsByComponent = newColorViewsByComponent;
    [newColorViewsByComponent release];
    
    [self updateColorViewFrames];
}

- (UIButton *)addButton {
    if (auto addButton = _addButton) return addButton;
    
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"plus"];
    
    UIButton *addButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    
    [addButton addTarget:self action:@selector(didTriggerAddButton:) forControlEvents:UIControlEventPrimaryActionTriggered];
    
    _addButton = [addButton retain];
    return addButton;
}

- (void)didTriggerPanGestureRecognizer:(UIPanGestureRecognizer *)sender {
    auto block = ^(UIPanGestureRecognizer *gesture, __kindof UIView *colorView, CGFloat initialPositionX){
        CGRect frame = colorView.frame;
        CGFloat newX = initialPositionX + [gesture translationInView:self].x;
        newX = MIN(newX, CGRectGetWidth(self.bounds) - CGRectGetWidth(colorView.bounds) * 0.5);
        newX = MAX(newX, -CGRectGetWidth(colorView.bounds) * 0.5);
        frame.origin.x = newX;
        colorView.frame = frame;
        
        NSMutableDictionary<ColorComponent *, __kindof UIView *> *colorViewsByComponent = [self.colorViewsByComponent mutableCopy];
        
        ColorComponent *oldComponent = [colorViewsByComponent allKeysForObject:colorView][0];
        [colorViewsByComponent removeObjectForKey:oldComponent];
        
        ColorComponent *newComponent = [oldComponent compnentByApplingLevel:(CGRectGetMinX(colorView.frame) + CGRectGetWidth(colorView.bounds) * 0.5) / CGRectGetWidth(self.bounds)];
        colorViewsByComponent[newComponent] = colorView;
        
        _colorViewsByComponent = [colorViewsByComponent retain];
        [colorViewsByComponent release];
        
        [self.delegate colorsRulerView:self didChangeComponents:self.components];
    };
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            CGPoint location = [sender locationInView:self];
            __kindof UIView * _Nullable targetView = [self colorViewAtLocation:location];
            
            if (targetView == nil) break;
            
            [self bringSubviewToFront:targetView];
            
            CGFloat draggingColorViewInitialPositionX = CGRectGetMinX(targetView.frame);
            
            self.draggingColorView = targetView;
            self.draggingColorViewInitialPositionX = draggingColorViewInitialPositionX;
            
            block(sender, targetView, draggingColorViewInitialPositionX);
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            __kindof UIView * _Nullable draggingColorView = self.draggingColorView;
            
            if (draggingColorView != nil) {
                block(sender, draggingColorView, self.draggingColorViewInitialPositionX);
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded: {
            __kindof UIView * _Nullable draggingColorView = self.draggingColorView;
            
            if (draggingColorView != nil) {
                block(sender, draggingColorView, self.draggingColorViewInitialPositionX);
            }
            
            self.draggingColorView = nil;
            break;
        }
        default:
            self.draggingColorView = nil;
            break;
    }
}

- (void)didTriggerTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    for (UIContextMenuInteraction *contextMenuInteraction in sender.view.interactions) {
        if (![contextMenuInteraction isKindOfClass:UIContextMenuInteraction.class]) continue;
        
        CGPoint location = [sender locationInView:sender.view];
        reinterpret_cast<void (*)(id, SEL, CGPoint)>(objc_msgSend)(contextMenuInteraction, sel_registerName("_presentMenuAtLocation:"), location);
    }
}

- (void)startEditingColorWithComponent:(ColorComponent *)component {
    UIColorPickerViewController *colorPickerViewController = [UIColorPickerViewController new];
    colorPickerViewController.selectedColor = component.color;
    colorPickerViewController.supportsAlpha = NO;
    colorPickerViewController.delegate = self;
    colorPickerViewController.modalPresentationStyle = UIModalPresentationPopover;
    colorPickerViewController.popoverPresentationController.sourceView = self.colorViewsByComponent[component];
    
    objc_setAssociatedObject(colorPickerViewController, ColorsRulerView.componentKey, component, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    __kindof UIViewController *viewController = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_viewControllerForAncestor"));
    
    [viewController presentViewController:colorPickerViewController animated:YES completion:nil];
    [colorPickerViewController release];
}

- (void)removeComponent:(ColorComponent *)component {
    NSMutableDictionary<ColorComponent *, __kindof UIView *> *colorViewsByComponent = [self.colorViewsByComponent mutableCopy];
    
    [colorViewsByComponent[component] removeFromSuperview];
    [colorViewsByComponent removeObjectForKey:component];
    
    self.colorViewsByComponent = colorViewsByComponent;
    [colorViewsByComponent release];
    
    [self.delegate colorsRulerView:self didChangeComponents:self.components];
}

- (void)didTriggerAddButton:(UIButton *)sender {
    UIColorPickerViewController *colorPickerViewController = [UIColorPickerViewController new];
    colorPickerViewController.supportsAlpha = NO;
    colorPickerViewController.delegate = self;
    colorPickerViewController.modalPresentationStyle = UIModalPresentationPopover;
    colorPickerViewController.popoverPresentationController.sourceView = sender;
    
    __kindof UIViewController *viewController = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_viewControllerForAncestor"));
    
    [viewController presentViewController:colorPickerViewController animated:YES completion:nil];
    [colorPickerViewController release];
}

- (__kindof UIView *)makeColorViewWithCompoent:(ColorComponent *)component {
    UIBackgroundConfiguration *configuration = [UIBackgroundConfiguration clearConfiguration];
    configuration.backgroundColor = component.color;
    configuration.strokeColor = UIColor.whiteColor;
    configuration.strokeWidth = 5.;
    configuration.shadowProperties.color = UIColor.blackColor;
    configuration.shadowProperties.radius = 5.;
    configuration.shadowProperties.opacity = 0.3;
    
    __kindof UIView *colorView =reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("_UISystemBackgroundView") alloc], sel_registerName("initWithConfiguration:"), configuration);
    
    UIContextMenuInteraction *contextMenuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [colorView addInteraction:contextMenuInteraction];
    [contextMenuInteraction release];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTriggerTapGestureRecognizer:)];
    [colorView addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    
    return [colorView autorelease];
}

- (void)updateColorViewFrames {
    CGRect addButtonFrame = self.addButton.frame;
    CGFloat colorViewHeight = CGRectGetHeight(self.bounds) - CGRectGetHeight(addButtonFrame) - 2. * 8.;
    CGFloat width = CGRectGetWidth(self.bounds);
    
    [self.colorViewsByComponent enumerateKeysAndObjectsUsingBlock:^(ColorComponent * _Nonnull component, UIView * _Nonnull colorView, BOOL * _Nonnull stop) {
        colorView.frame = CGRectMake(width * component.level - colorViewHeight * 0.5,
                                     CGRectGetHeight(addButtonFrame) + 8.,
                                     colorViewHeight,
                                     colorViewHeight);
        
        UIBackgroundConfiguration *configuration = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(colorView, sel_registerName("configuration"));
        configuration.cornerRadius = colorViewHeight * 0.4;
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(colorView, sel_registerName("setConfiguration:"), configuration);
    }];
}

- (__kindof UIView * _Nullable)colorViewAtLocation:(CGPoint)location {
    __kindof UIView * _Nullable targetView = nil;
    for (__kindof UIView *colorView in self.colorViewsByComponent.allValues) {
        CGRect frame = CGRectInset([colorView frameInView:self], -10., -10.);
        
        if (CGRectContainsPoint(frame, location)) {
            if (targetView == nil) {
                targetView = colorView;
            } else {
                NSInteger index1 = [self.subviews indexOfObject:targetView];
                NSInteger index2 = [self.subviews indexOfObject:colorView];
                assert(index1 != NSNotFound);
                assert(index2 != NSNotFound);
                
                if (index1 < index2) {
                    targetView = colorView;
                }
            }
        }
    }
    
    return targetView;
}

- (void)colorPickerViewController:(UIColorPickerViewController *)viewController didSelectColor:(UIColor *)color continuously:(BOOL)continuously {
    if (ColorComponent *editingComponent = objc_getAssociatedObject(viewController, ColorsRulerView.componentKey)) {
        ColorComponent *newComponent = [editingComponent compnentByApplingColor:color];
        NSMutableDictionary<ColorComponent *, __kindof UIView *> *colorViewsByComponent = [self.colorViewsByComponent mutableCopy];
        
        __kindof UIView *colorView = colorViewsByComponent[editingComponent];
        UIBackgroundConfiguration *configuration = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(colorView, sel_registerName("configuration"));
        configuration.backgroundColor = color;
        reinterpret_cast<void (*)(id, SEL, id)>(objc_msgSend)(colorView, sel_registerName("setConfiguration:"), configuration);
        
        [colorViewsByComponent removeObjectForKey:editingComponent];
        colorViewsByComponent[newComponent] = colorView;
        
        self.colorViewsByComponent = colorViewsByComponent;
        [colorViewsByComponent release];
        
        objc_setAssociatedObject(viewController, ColorsRulerView.componentKey, newComponent, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self.delegate colorsRulerView:self didChangeComponents:self.components];
    } else {
        NSMutableSet<ColorComponent *> *components = [self.components mutableCopy];
        
        ColorComponent *component = [[ColorComponent alloc] initWithLevel:0.5f color:color];
        [components addObject:component];
        
        self.components = components;
        [components release];
        
        objc_setAssociatedObject(viewController, ColorsRulerView.componentKey, component, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [component release];
        
        [self.delegate colorsRulerView:self didChangeComponents:self.components];
    }
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    __weak auto weakSelf = self;
    ColorComponent *component = [self.colorViewsByComponent allKeysForObject:interaction.view][0];
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:^UIViewController * _Nullable{
        return nil;
    }
                                                                                         actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        NSMutableArray<UIMenuElement *> *children = [suggestedActions mutableCopy];
        
        UIAction *editAction = [UIAction actionWithTitle:@"Edit Color" image:[UIImage systemImageNamed:@"paintpalette"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf startEditingColorWithComponent:component];
        }];
        
        UIAction *removeAction = [UIAction actionWithTitle:@"Remove" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf removeComponent:component];
        }];
        
        removeAction.attributes = UIMenuOptionsDestructive;
        
        [children addObjectsFromArray:@[editAction, removeAction]];
        
        UIMenu *menu = [UIMenu menuWithChildren:children];
        [children release];
        
        return menu;
    }];
    
    return configuration;
}

@end
