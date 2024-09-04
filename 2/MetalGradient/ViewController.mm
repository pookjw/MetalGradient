//
//  ViewController.mm
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/3/24.
//

#import "ViewController.h"
#import "ColorsRulerView.h"
#import "ColorGradientView.h"

@interface ViewController () <ColorsRulerViewDelegate>
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) ColorsRulerView *rulerView;
@property (retain, nonatomic, readonly) ColorGradientView *gradientView;
@end

@implementation ViewController
@synthesize stackView = _stackView;
@synthesize rulerView = _rulerView;
@synthesize gradientView = _gradientView;

- (void)dealloc {
    [_stackView release];
    [_rulerView release];
    [_gradientView release];
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
    
    self.rulerView.components = [NSSet setWithArray:@[
        [ColorComponent componentByLevel:0.3 color:UIColor.redColor],
        [ColorComponent componentByLevel:0.7 color:UIColor.cyanColor]
    ]];
    self.gradientView.components = self.rulerView.components;
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.rulerView,
        self.gradientView
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 0.;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (ColorsRulerView *)rulerView {
    if (auto rulerView = _rulerView) return rulerView;
    
    ColorsRulerView *rulerView = [ColorsRulerView new];
    rulerView.delegate = self;
    
    _rulerView = [rulerView retain];
    return [rulerView autorelease];
}

- (ColorGradientView *)gradientView {
    if (auto gradientView = _gradientView) return gradientView;
    
    ColorGradientView *gradientView = [[ColorGradientView alloc] initWithFrame:self.view.bounds];
    
    _gradientView = [gradientView retain];
    return [gradientView autorelease];
}

- (void)colorsRulerView:(ColorsRulerView *)colorsRulerView didChangeComponents:(NSSet<ColorComponent *> *)components {
    self.gradientView.components = components;
}

@end
