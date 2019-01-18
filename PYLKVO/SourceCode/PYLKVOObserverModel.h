//
//  PYLKVOObserverModel.h
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+PYLKVO.h"

@interface PYLKVOObserverModel : NSObject
@property (nonatomic, weak) id observer;
@property (nonatomic, copy) NSString *observerMemAddr;
@property (nonatomic, copy) NSString *keypath;
@property (nonatomic, assign) PYLKVOOptions options;
@end
