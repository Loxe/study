//
//  MVPViewController.m
//  Test
//
//  Created by huangzhen on 2019/12/4.
//  Copyright © 2019 vine. All rights reserved.
//

#import "MVPViewController.h"
#import "MVPPresenter.h"
#import "MVPView.h"

@interface MVPViewController () <MVPPresenterProtocol>

@property (nonatomic, strong) MVPView *testView;
@property (nonatomic, strong) MVPPresenter *presenter;

@end

@implementation MVPViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];

    self.presenter = [MVPPresenter new];
    self.presenter.delegate = self;
    
    [self.presenter fetchData];
}

- (void)setupViews {
    self.testView = [[MVPView alloc] initWithFrame:CGRectMake(100, 100, CGRectGetWidth(self.view.bounds)-200, 50)];
    [self.view addSubview:self.testView];
}

#pragma mak - MVPPresenterProtocol
- (void)updateData {
    if (self.presenter.model.firstName.length > 0) {
        self.testView.nameLabel.text = self.presenter.model.firstName;
    } else {
        self.testView.nameLabel.text = self.presenter.model.lastName;
    }
}

@end
