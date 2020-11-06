//
//  MVPPresenter.m
//  Test
//
//  Created by huangzhen on 2019/12/4.
//  Copyright © 2019 vine. All rights reserved.
//

#import "MVPPresenter.h"

@interface MVPPresenter()

@end

@implementation MVPPresenter

- (void)fetchData {
    self.model = [[MVPModel alloc] initWithFirstName:@"赵丽颖" lastName:@"胡歌"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateData)]) {
        [self.delegate updateData];
    }
}

@end
