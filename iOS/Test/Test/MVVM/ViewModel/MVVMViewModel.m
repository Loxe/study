//
//  MVVMViewModel.m
//  Test
//
//  Created by huangzhen on 2019/12/4.
//  Copyright © 2019 vine. All rights reserved.
//

#import "MVVMViewModel.h"

@implementation MVVMViewModel

- (instancetype)initWithModel:(MVVMModel *)model {
    self = [super init];
        if (self) {
            _model = model;
            if (model.firstName.length > 0) {
                _nameText = model.firstName;
            } else {
                _nameText = model.lastName;
            }
        }
        return self;
}

@end
