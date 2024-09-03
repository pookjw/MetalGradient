//
//  ColorsRulerView.mm
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/3/24.
//

#import "ColorsRulerView.h"
#import <objc/message.h>
#import <objc/runtime.h>

@interface ColorsRulerView () <UIColorPickerViewControllerDelegate>
@property (retain, nonatomic, readonly) UIButton *addButton;
@property (retain, nonatomic, readonly) NSMutableArray<UIButton *> *colorComponentButtons;
@end

@implementation ColorsRulerView
@synthesize addButton = _addButton;

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
    [_colorComponents release];
    [_addButton release];
    [super dealloc];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(200., CGRectGetHeight(self.addButton.frame) + 100.);
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    NSLog(@"%@", NSStringFromCGRect(bounds));
}

- (void)ColorsRulerView_commonInit {
    self.backgroundColor = UIColor.systemGrayColor;
    
    _colorComponents = [NSArray new];
    _colorComponentButtons = [NSMutableArray new];
    
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
    
//    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:didTriggerPanGestureRecognizer:];
}

- (void)setColorComponents:(NSArray<ColorComponent *> *)colorComponents {
    [_colorComponents release];
    _colorComponents = [colorComponents copy];
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

- (UIButton *)makeColorComponentButtonWithCompoent:(ColorComponent *)component {
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    
    UIBackgroundConfiguration *background = [UIBackgroundConfiguration clearConfiguration];
    background.backgroundColor = [UIColor colorWithRed:component.color.x green:component.color.y blue:component.color.z alpha:1.];
    background.strokeColor = UIColor.whiteColor;
    background.strokeWidth = 5.;
    background.shadowProperties.color = UIColor.blackColor;
    
    configuration.background = background;
    
    UIButton *colorComponentButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    
    return colorComponentButton;
}

- (void)colorPickerViewController:(UIColorPickerViewController *)viewController didSelectColor:(UIColor *)color continuously:(BOOL)continuously {
    
}

@end
