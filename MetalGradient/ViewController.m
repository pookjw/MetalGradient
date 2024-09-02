//
//  ViewController.m
//  MetalGradient
//
//  Created by Jinwoo Kim on 9/1/24.
//

#import "ViewController.h"
#import "Renderer.h"

@interface ViewController ()
@property (retain, readonly, nonatomic) Renderer *renderer;
@end

@implementation ViewController

- (void)dealloc {
    [_renderer release];
    [super dealloc];
}

- (void)loadView {
    MTKView *view = [MTKView new];
    self.view = view;
    [view release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Renderer *renderer = [[Renderer alloc] initWithView:(MTKView *)self.view];
    _renderer = [renderer retain];
    [renderer release];
}

@end
