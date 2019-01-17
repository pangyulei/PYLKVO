//
//  Father.h
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"
@class Daughter;
NS_ASSUME_NONNULL_BEGIN

@interface Father : Person
@property (nonatomic, strong) Daughter *daughter;
@end

NS_ASSUME_NONNULL_END
