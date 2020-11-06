//
//  MVPPresenter.h
//  Test
//
//  Created by huangzhen on 2019/12/4.
//  Copyright © 2019 vine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVPPresenterProtocol.h"
#import "MVPModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MVPPresenter : NSObject

@property (nonatomic, strong) MVPModel *model;

@property (nonatomic, weak) id<MVPPresenterProtocol> delegate;

- (void)fetchData;

@end

NS_ASSUME_NONNULL_END
