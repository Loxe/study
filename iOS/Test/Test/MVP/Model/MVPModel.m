//
//  MVPModel.m
//  Test
//
//  Created by huangzhen on 2019/12/4.
//  Copyright © 2019 vine. All rights reserved.
//

#import "MVPModel.h"

@implementation MVPModel

- (instancetype)initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName {
    self = [super init];
    if (self) {
        _firstName = firstName;
        _lastName = lastName;
    }
    return self;
}

@end
