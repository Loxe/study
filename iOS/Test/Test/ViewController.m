//
//  ViewController.m
//  Test
//
//  Created by admin on 2019/10/12.
//  Copyright © 2019 vine. All rights reserved.
//

#import "ViewController.h"
#import "HZAutoreleasePoolTest.h"
#import "HZRecorder.h"
#import "GCDTest.h"
#import "HZViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) HZRecorder *recorder;
@property (nonatomic, strong) UIView *testView;
@property (nonatomic, assign) BOOL shouldNotCalculateFrame;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self createUI];
    
    //[HZAutoreleasePoolTest addRunLoopObserver];
    //self.recorder = [[HZRecorder alloc] init];
    //[GCDTest groupTest];
}

- (void)createUI {
    self.button = [[UIButton alloc] init];
    [self.button setTitle:@"按钮" forState:UIControlStateNormal];
    self.button.backgroundColor = [UIColor greenColor];
    [self.button addTarget:self action:@selector(buttonDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button];
    
    self.testView = [[UIView alloc] init];
    self.testView.backgroundColor = [UIColor redColor];
    //self.testView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"logo"]];
    [self.view addSubview:self.testView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.shouldNotCalculateFrame) {
        return;
    }
    
    const CGFloat width = self.view.bounds.size.width;
    const CGFloat height = self.view.bounds.size.height;
    
    CGFloat x = 40.0f;
    CGFloat y = 100.0f;
    CGFloat w = 100.0f;
    CGFloat h = 40.0f;
    self.button.frame = CGRectMake(x, y, w, h);
    
    w = 200.0f;
    h = 100.0f;
    x = (width - w) / 2;
    y = (height - h) / 2;
    self.testView.frame = CGRectMake(x, y, w, h);
}

#pragma mark - 按钮事件
- (void)buttonDidTouchUpInside:(UIButton *)button {
    HZViewController *vc = [[HZViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

@end
