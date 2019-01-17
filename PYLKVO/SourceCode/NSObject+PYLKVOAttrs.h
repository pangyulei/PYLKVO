//
//  NSObject+PYLKVOObserverModel.h
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PYLKVOObserverModel;

@interface NSObject (PYLKVOAttrs)
@property (nonatomic, strong) NSMutableArray<PYLKVOObserverModel *> *pyl_kvo_observerModels;
@property (nonatomic, weak) NSObject *pyl_kvo_retainBy;
@end
