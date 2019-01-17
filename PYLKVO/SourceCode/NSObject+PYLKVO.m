//
//  NSObject+PYLKVO.m
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "NSObject+PYLKVO.h"
#import "NSObject+PYLKVOAttrs.h"
#import "PYLKVOObserverModel.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString * const PYLKVOKeyNew = @"PYLKVOKeyNew";
NSString * const PYLKVOKeyOld = @"PYLKVOKeyOld";
static NSString * const PYLKVOClassPrefix = @"PYLKVOClass_";

@implementation NSObject (PYLKVO)

- (void)pyl_kvo_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(PYLKVOOptions)options {
    
    [self pyl_kvo_isaSwizzleWithKeyPath:keyPath];
    
    PYLKVOObserverModel *observerModel = [PYLKVOObserverModel new];
    observerModel.observer = observer;
    observerModel.keypath = keyPath;
    observerModel.options = options;
    if (!self.pyl_kvo_observerModels) {
        self.pyl_kvo_observerModels = @[].mutableCopy;
    }
    [self.pyl_kvo_observerModels addObject:observerModel];
    
    if (options & PYLKVOOptionsInitial) {
        ((void(*)(id,SEL,id,id,id))(void *)objc_msgSend)(self, @selector(pyl_kvo_observeValueForKeyPath:ofObject:change:), keyPath, self, nil);
    }
}

- (void)pyl_kvo_isaSwizzleWithKeyPath:(NSString *)keyPath {
    NSArray<NSString *> *attrs = [keyPath componentsSeparatedByString:@"."];
    id previousObj = self;
    for (NSUInteger i = 0; i < attrs.count; i++) {
        NSString *attrName = attrs[i];
        SEL getAttrSEL = sel_registerName(attrName.UTF8String);
        SEL setAttrSEL = sel_registerName([NSString stringWithFormat:@"set%@:", attrName.capitalizedString].UTF8String);
        if ([previousObj respondsToSelector:setAttrSEL]) {
            [self pyl_kvo_isaSwizzleObject:previousObj WithSEL:setAttrSEL];
        }
        if ([previousObj respondsToSelector:getAttrSEL]) {
            NSObject *newPreviousObj = ((id(*)(id,SEL))(void *)objc_msgSend)(previousObj, getAttrSEL);
            newPreviousObj.pyl_kvo_retainBy = previousObj;
            previousObj = newPreviousObj;
        }
    }
}

- (void)pyl_kvo_isaSwizzleObject:(id)object WithSEL:(SEL)setterSEL {
    const char *subclassName = subclassNameForSuperclass(object_getClass(object));
    
    //如果子类不存在就生成
    Class subclass = objc_getClass(subclassName);
    if (!subclass) {
        subclass = objc_allocateClassPair(object_getClass(object), subclassName, 0);
        if (subclass) {
            objc_registerClassPair(subclass);
        } else {
            //动态创建类失败
            return;
        }
    }
    
    //重写 setter 方法
    const char *typeEncoding = method_getTypeEncoding(class_getInstanceMethod(object_getClass(object), setterSEL)); //写死 "v@:@" 也行
    class_addMethod(subclass, setterSEL, (IMP)pyl_kvo_setterSEL, typeEncoding);
    //改变原有类的 isa
    object_setClass(object, subclass);
}

void pyl_kvo_setterSEL(NSObject *self, SEL cmd, id newValue) {
    
    NSObject *rootListener = self; //原始的被监听者
    while (rootListener.pyl_kvo_retainBy) {
        rootListener = rootListener.pyl_kvo_retainBy;
    }
    //setDaughter: -> daughter
    NSString *methodName = [NSString stringWithFormat:@"%s", sel_getName(cmd)];
    methodName = [methodName substringFromIndex:3];
    methodName = [methodName substringToIndex:methodName.length-1]; //Daughter
    methodName = [methodName lowercaseString]; //daughter
    
    //通知
    NSMutableArray<PYLKVOObserverModel *> *notifys = @[].mutableCopy;
    
    for (PYLKVOObserverModel *observerModel in rootListener.pyl_kvo_observerModels) {
        NSArray *components = [observerModel.keypath componentsSeparatedByString:@"."];
        if ([components containsObject:methodName]) {
            [notifys addObject:observerModel];
        }
    }
    BOOL hasSetNewValue = NO;
    for (PYLKVOObserverModel *observerModel in notifys) {
        NSMutableDictionary *dict = @{}.mutableCopy;
        
        //old value 需要根据 keypath 遍历到最后一个元素才能决定取哪个 value
        //@"daughter.name"
        SEL getAttrSEL = sel_registerName(methodName.UTF8String);
        id oldValue = ((id(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL);
        NSRange range = [observerModel.keypath rangeOfString:methodName];
        BOOL hasMoreAttr = (range.location+range.length) != observerModel.keypath.length;
        id endNewValue = newValue;
        if (hasMoreAttr) {
            //后面还有更多属性
            NSString *moreAttrs = [observerModel.keypath substringFromIndex:range.location+range.length+1];
            NSArray *components = [moreAttrs componentsSeparatedByString:@"."];
            for (NSString *str in components) {
                getAttrSEL = sel_registerName(str.UTF8String);
                if ([oldValue respondsToSelector:getAttrSEL]) {
                    oldValue = ((id(*)(id,SEL))(void *)objc_msgSend)(oldValue, getAttrSEL);
                }
                if ([endNewValue respondsToSelector:getAttrSEL]) {
                    endNewValue = ((id(*)(id,SEL))(void *)objc_msgSend)(endNewValue, getAttrSEL);
                }
            }
            
            //如果不是最终的值，需要重新改  isa, 比如 @" father.daughter.name = @"lucy" ", 之前改过 daughter 的 isa，但是此时如果 father.daughter = xxx, 就会重置，需要重新改 isa
//            [rootListener pyl_kvo_isaSwizzleWithKeyPath:observerModel.keypath];
            [newValue setPyl_kvo_retainBy:self];
            [newValue pyl_kvo_isaSwizzleWithKeyPath:moreAttrs];
            
        }
        
        //调用父类实现设置新值
        if (!hasSetNewValue) {
            IMP superIMP = class_getMethodImplementation(class_getSuperclass(object_getClass(self)), cmd);
            ((void(*)(id,SEL,id))(void *)superIMP)(self, cmd, newValue);
            hasSetNewValue = YES;
        }
        
        if (observerModel.options & PYLKVOOptionsOld) {
            dict[PYLKVOKeyOld] = oldValue;
        }
        if (observerModel.options & PYLKVOOptionsNew) {
            dict[PYLKVOKeyNew] = endNewValue;
        }
        if ([observerModel.observer respondsToSelector:@selector(pyl_kvo_observeValueForKeyPath:ofObject:change:)]) {
            ((void(*)(id,SEL,id,id,id))(void *)objc_msgSend)(observerModel.observer, @selector(pyl_kvo_observeValueForKeyPath:ofObject:change:), observerModel.keypath, rootListener, dict);
        }
    }
}

const char * subclassNameForSuperclass(Class superclass) {
    NSString *name = [NSString stringWithFormat:@"%@%s", PYLKVOClassPrefix, class_getName(superclass)];
    return name.UTF8String;
}

- (void)pyl_kvo_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    
}

- (void)pyl_kvo_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString*,id> *)change {
    //子类实现, 接收消息
}

@end
