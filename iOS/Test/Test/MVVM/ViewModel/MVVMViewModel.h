//
//  MVVMViewModel.h
//  Test
//
//  Created by huangzhen on 2019/12/4.
//  Copyright © 2019 vine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVVMModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MVVMViewModel : NSObject

@property (nonatomic, readonly) MVVMModel *model;
@property (nonatomic, readonly) NSString *nameText;

- (instancetype)initWithModel:(MVVMModel *)model;

@end

NS_ASSUME_NONNULL_END
