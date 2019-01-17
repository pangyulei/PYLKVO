//
//  NSObject+PYLKVOObserverModel.m
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "NSObject+PYLKVOAttrs.h"
#import <objc/runtime.h>

@implementation NSObject (PYLKVOAttrs)
@dynamic pyl_kvo_observerModels, pyl_kvo_retainBy;

- (void)setPyl_kvo_observerModels:(NSMutableArray<PYLKVOObserverModel *> *)pyl_kvo_observerModels {
    SEL aSEL = @selector(pyl_kvo_observerModels);
    objc_setAssociatedObject(self, sel_getName(aSEL), pyl_kvo_observerModels, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray<PYLKVOObserverModel *> *)pyl_kvo_observerModels {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPyl_kvo_retainBy:(id)pyl_kvo_retainBy {
    objc_setAssociatedObject(self, @selector(pyl_kvo_retainBy), pyl_kvo_retainBy, OBJC_ASSOCIATION_ASSIGN);
}

- (id)pyl_kvo_retainBy {
    return objc_getAssociatedObject(self, _cmd);
}

@end
