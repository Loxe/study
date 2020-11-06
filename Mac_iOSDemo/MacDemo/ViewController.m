//
//  ViewController.m
//  MacDemo
//
//  Created by Apple on 2020/10/25.
//  Copyright © 2020 JinTao. All rights reserved.
//

#import "ViewController.h"
#import "ffplay.h"

@interface ViewController ()

@property (nonatomic, strong) NSButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.button = [NSButton buttonWithTitle:@"123456" target:self action:@selector(buttonDidClick)];
    [self.view addSubview:self.button];
}

- (void)viewDidLayout {
    [super viewDidLayout];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)buttonDidClick {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"mp4"];
    ffplay([path UTF8String]);
}

@end
