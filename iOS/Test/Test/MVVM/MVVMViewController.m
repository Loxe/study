//
//  MVVMViewController.m
//  Test
//
//  Created by huangzhen on 2019/12/4.
//  Copyright © 2019 vine. All rights reserved.
//

#import "MVVMViewController.h"
#import "MVVMViewModel.h"
#import "MVVMView.h"

@interface MVVMViewController ()

@property (nonatomic, strong) MVVMView *testView;
@property (nonatomic, strong) MVVMViewModel *viewModel;

@end

@implementation MVVMViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];

    self.testView.nameLabel.text = self.viewModel.nameText;
}

- (void)setupViews {
    MVVMModel *model = [[MVVMModel alloc] initWithFirstName:@"" lastName:@"胡歌"];
    self.viewModel = [[MVVMViewModel alloc] initWithModel:model];
    self.testView = [[MVVMView alloc] initWithFrame:CGRectMake(100, 100, CGRectGetWidth(self.view.bounds)-200, 50)];
    [self.view addSubview:self.testView];
}

@end
