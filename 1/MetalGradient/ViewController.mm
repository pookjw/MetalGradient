//
//  ViewController.mm
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/1/24.
//

#import "ViewController.h"
#import "Renderer.h"

@interface ViewController ()
@property (retain, readonly, nonatomic) UIStackView *stackView;
@property (retain, readonly, nonatomic) MTKView *mtkView;
@property (retain, readonly, nonatomic) UIButton *styleMenuButton;
@property (retain, readonly, nonatomic) Renderer *renderer;
@end

@implementation ViewController
@synthesize stackView = _stackView;
@synthesize mtkView = _mtkView;
@synthesize styleMenuButton = _styleMenuButton;
@synthesize renderer = _renderer;

- (void)dealloc {
    [_stackView release];
    [_mtkView release];
    [_styleMenuButton release];
    [_renderer release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    UIStackView *stackView = self.stackView;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    
    self.navigationItem.hidesBackButton = YES;
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.mtkView,
        self.styleMenuButton
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (MTKView *)mtkView {
    if (auto mtkView = _mtkView) return mtkView;
    
    MTKView *mtkView = [MTKView new];
    
    _mtkView = [mtkView retain];
    return [mtkView autorelease];
}

- (UIButton *)styleMenuButton {
    if (auto styleMenuButton = _styleMenuButton) return styleMenuButton;
    
    UIButton *styleMenuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    styleMenuButton.changesSelectionAsPrimaryAction = YES;
    styleMenuButton.showsMenuAsPrimaryAction = YES;
    
    
    NSUInteger count;
    RendererStyle *styles = RendererStyleMethodAllValues(&count);
    RendererStyle selectedStyle = self.renderer.style;
    Renderer *renderer = self.renderer;
    
    NSMutableArray<UIMenuElement *> *children = [[NSMutableArray alloc] initWithCapacity:count];
    
    for (NSUInteger index = 0; index < count; index++) {
        RendererStyle style = styles[index];
        
        UIAction *action = [UIAction actionWithTitle:NSStringFromRenderDispatchMethod(style) image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            renderer.style = style;
        }];
        
//        action.attributes = UIMenuElementAttributesKeepsMenuPresented;
        action.state = (style == selectedStyle) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        [children addObject:action];
    }
    
    UIMenu *menu = [UIMenu menuWithChildren:children];
    [children release];
    
    styleMenuButton.menu = menu;
    
    _styleMenuButton = [styleMenuButton retain];
    return styleMenuButton;
}

- (Renderer *)renderer {
    if (auto renderer = _renderer) return renderer;
    
    Renderer *renderer = [[Renderer alloc] initWithView:self.mtkView];
    
    _renderer = [renderer retain];
    return [renderer autorelease];
}

@end
