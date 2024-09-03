//
//  ViewController.mm
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/3/24.
//

#import "ViewController.h"
#import "ColorsRulerView.h"
#import <MetalKit/MetalKit.h>

@interface ViewController () <ColorsRulerViewDelegate>
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) ColorsRulerView *colorsRulerView;
@property (retain, nonatomic, readonly) MTKView *mtkView;
@end

@implementation ViewController
@synthesize stackView = _stackView;
@synthesize colorsRulerView = _colorsRulerView;
@synthesize mtkView = _mtkView;

- (void)dealloc {
    [_stackView release];
    [_colorsRulerView release];
    [_mtkView release];
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
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.colorsRulerView,
        self.mtkView
    ]];
    
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 8.;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (ColorsRulerView *)colorsRulerView {
    if (auto colorsRulerView = _colorsRulerView) return colorsRulerView;
    
    ColorsRulerView *colorsRulerView = [ColorsRulerView new];
    colorsRulerView.delegate = self;
    
    _colorsRulerView = [colorsRulerView retain];
    return [colorsRulerView autorelease];
}

- (MTKView *)mtkView {
    if (auto mtkView = _mtkView) return mtkView;
    
    MTKView *mtkView = [MTKView new];
    
    _mtkView = [mtkView retain];
    return [mtkView autorelease];
}

- (void)colorsRulerView:(ColorsRulerView *)colorsRulerView didChangeColorComponents:(NSArray<ColorComponent *> *)colorComponents {
    
}

@end
