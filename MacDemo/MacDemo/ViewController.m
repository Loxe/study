//
//  ViewController.m
//  MacDemo
//
//  Created by JinTao on 2020/12/7.
//

#import "ViewController.h"
#import <CoreMediaIO/CMIOHardwareDevice.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    button.title = @"214343";
    [self.view addSubview:button];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
