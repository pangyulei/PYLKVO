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
//
//typedef NS_ENUM(NSInteger) {
//    PYLKVO_CHAR,
//    PYLKVO_INT,
//    PYLKVO_SHORT,
//    PYLKVO_LONG,
//    PYLKVO_LONG_LONG,
//    PYLKVO_BOOL,
//    PYLKVO_FLOAT,
//    PYLKVO_DOUBLE,
//    PYLKVO_UNSIGNED_CHAR,
//    PYLKVO_UNSIGNED_INT,
//    PYLKVO_UNSIGNED_SHORT,
//    PYLKVO_UNSIGNED_LONG,
//    PYLKVO_UNSIGNED_LONG_LONG,
//} PYLKVO_TYPE;

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
        ((void(*)(id,SEL,id,id,id))(void *)objc_msgSend)(observer, @selector(pyl_kvo_observeValueForKeyPath:ofObject:change:), keyPath, self, @{});
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
            [previousObj pyl_kvo_isaSwizzleWithSetterSEL:setAttrSEL];
        }
        BOOL isLast = (i == attrs.count - 1);
        if (!isLast && [previousObj respondsToSelector:getAttrSEL]) {
            NSObject *newPreviousObj = ((id(*)(id,SEL))(void *)objc_msgSend)(previousObj, getAttrSEL);
            newPreviousObj.pyl_kvo_retainBy = previousObj;
            previousObj = newPreviousObj;
        }
    }
}

- (void)pyl_kvo_isaSwizzleWithSetterSEL:(SEL)setterSEL {
    const char *subclassName = pyl_kvo_subclassName(object_getClass(self));
    
    //如果子类不存在就生成
    Class subclass = objc_getClass(subclassName);
    if (!subclass) {
        subclass = objc_allocateClassPair(object_getClass(self), subclassName, 0);
        if (subclass) {
            objc_registerClassPair(subclass);
        } else {
            //动态创建类失败
            return;
        }
    }
    
    //重写 setter 方法
    const char *typeEncoding = method_getTypeEncoding(class_getInstanceMethod(object_getClass(self), setterSEL));
    IMP newSetterIMP = pyl_kvo_impWithTypeEncoding(typeEncoding);
    class_addMethod(subclass, setterSEL, newSetterIMP, typeEncoding);
    //改变原有类的 isa
    object_setClass(self, subclass);
}

//处理基本数据类型
void pyl_kvo_setter_short(NSObject *self, SEL cmd, short newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_unsigned_short(NSObject *self, SEL cmd, unsigned short newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_int(NSObject *self, SEL cmd, int newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_unsigned_int(NSObject *self, SEL cmd, unsigned int newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_long(NSObject *self, SEL cmd, long newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_unsigned_long(NSObject *self, SEL cmd, unsigned long newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_long_long(NSObject *self, SEL cmd, long long newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_unsigned_long_long(NSObject *self, SEL cmd, unsigned long long newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_bool(NSObject *self, SEL cmd, BOOL newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_float(NSObject *self, SEL cmd, float newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_double(NSObject *self, SEL cmd, double newValue) {
    pyl_kvo_setter_basic(self, cmd, @(newValue));
}
void pyl_kvo_setter_unsigned_char(NSObject *self, SEL cmd, unsigned char newValue) {
    pyl_kvo_setter_basic(self, cmd, [NSString stringWithFormat:@"%c", newValue]);
}
void pyl_kvo_setter_char(NSObject *self, SEL cmd, char newValue) {
    pyl_kvo_setter_basic(self, cmd, [NSString stringWithFormat:@"%c", newValue]);
}

void pyl_kvo_setter_basic(NSObject *self, SEL cmd, id newValue) {
    NSObject *rootListener = self; //原始的被监听者
    while (rootListener.pyl_kvo_retainBy) {
        rootListener = rootListener.pyl_kvo_retainBy;
    }
    //setDaughter: -> daughter
    NSString *getterSELName = pyl_kvo_getterSELName(cmd);
    
    //通知
    NSMutableArray<PYLKVOObserverModel *> *notifys = @[].mutableCopy;
    
    for (PYLKVOObserverModel *observerModel in rootListener.pyl_kvo_observerModels) {
        NSArray *components = [observerModel.keypath componentsSeparatedByString:@"."];
        if ([components containsObject:getterSELName]) {
            [notifys addObject:observerModel];
        }
    }
    const char *typeEncoding = method_getTypeEncoding(class_getInstanceMethod(object_getClass(self), cmd));
    for (PYLKVOObserverModel *observerModel in notifys) {
        NSMutableDictionary *dict = @{}.mutableCopy;
        
        SEL getAttrSEL = sel_registerName(getterSELName.UTF8String);
        if (observerModel.options & PYLKVOOptionsOld) {
            dict[PYLKVOKeyOld] = pyl_kvo_oldValue(self, typeEncoding, getAttrSEL);
        }
        if (observerModel.options & PYLKVOOptionsNew) {
            dict[PYLKVOKeyNew] = newValue;
        }
        ((void(*)(id,SEL,id,id,id))(void *)objc_msgSend)(observerModel.observer, @selector(pyl_kvo_observeValueForKeyPath:ofObject:change:), observerModel.keypath, rootListener, dict);
    }
    
    //调用父类实现设置新值
    IMP superIMP = class_getMethodImplementation(class_getSuperclass(object_getClass(self)), cmd);
    pyl_kvo_set_newValue(superIMP, self, cmd, newValue, typeEncoding);
}

void pyl_kvo_set_newValue(IMP imp, id receiver, SEL cmd, id newValue, const char * typeEncoding) {
    NSString *type = [[NSString stringWithUTF8String:typeEncoding] substringFromIndex:@"v24@0:8".length];
    if ([type containsString:[NSString stringWithUTF8String:@encode(char)]]) {
        char c = [newValue charValue];
        ((void(*)(id,SEL,char))(void *)imp)(receiver, cmd, c);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(short)]]) {
        short s = [newValue shortValue];
        ((void(*)(id,SEL,short))(void *)imp)(receiver, cmd, s);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(int)]]) {
        ((void(*)(id,SEL,int))(void *)imp)(receiver, cmd, [newValue intValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long)]]) {
        ((void(*)(id,SEL,long))(void *)imp)(receiver, cmd, [newValue longValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long long)]]) {
        ((void(*)(id,SEL,long long))(void *)imp)(receiver, cmd, [newValue longLongValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned char)]]) {
        ((void(*)(id,SEL,unsigned char))(void *)imp)(receiver, cmd, [newValue unsignedCharValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
        ((void(*)(id,SEL,unsigned short))(void *)imp)(receiver, cmd, [newValue unsignedShortValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
        ((void(*)(id,SEL,unsigned int))(void *)imp)(receiver, cmd, [newValue unsignedIntValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
        ((void(*)(id,SEL,unsigned long))(void *)imp)(receiver, cmd, [newValue unsignedLongValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long long)]]) {
        ((void(*)(id,SEL,unsigned long long))(void *)imp)(receiver, cmd, [newValue unsignedLongLongValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(BOOL)]]) {
        ((void(*)(id,SEL,BOOL))(void *)imp)(receiver, cmd, [newValue boolValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(float)]]) {
        ((void(*)(id,SEL,float))(void *)imp)(receiver, cmd, [newValue floatValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(double)]]) {
        ((void(*)(id,SEL,double))(void *)imp)(receiver, cmd, [newValue doubleValue]);
    }
    
}

id pyl_kvo_oldValue(NSObject* self, const char *typeEncoding, SEL getAttrSEL) {
    NSString *type = [[NSString stringWithUTF8String:typeEncoding] substringFromIndex:@"v24@0:8".length];
    if ([type containsString:[NSString stringWithUTF8String:@encode(char)]]) {
        char oldValue = ((char(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL);
        return [NSString stringWithFormat:@"%c", oldValue];
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(short)]]) {
        return @(((short(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(int)]]) {
        return @(((int(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long)]]) {
        return @(((long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long long)]]) {
        return @(((long long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned char)]]) {
        char oldValue = ((unsigned char (*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL);
        return [NSString stringWithFormat:@"%c", oldValue];
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
        return @(((unsigned short(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
        return @(((unsigned int(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
        return @(((unsigned long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long long)]]) {
        return @(((unsigned long long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(bool)]]) {
        return @(((bool (*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(float)]]) {
        return @(((float (*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(double)]]) {
        return @(((double(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
    }
    return nil;
}

//处理对象
void pyl_kvo_setter_objc(NSObject *self, SEL cmd, id newValue) {
    
    NSObject *rootListener = self; //原始的被监听者
    while (rootListener.pyl_kvo_retainBy) {
        rootListener = rootListener.pyl_kvo_retainBy;
    }
    //setDaughter: -> daughter
    NSString *getterSELName = pyl_kvo_getterSELName(cmd);
    
    //通知
    NSMutableArray<PYLKVOObserverModel *> *notifys = @[].mutableCopy;
    
    for (PYLKVOObserverModel *observerModel in rootListener.pyl_kvo_observerModels) {
        NSArray *components = [observerModel.keypath componentsSeparatedByString:@"."];
        if ([components containsObject:getterSELName]) {
            [notifys addObject:observerModel];
        }
    }

    for (PYLKVOObserverModel *observerModel in notifys) {
        NSMutableDictionary *dict = @{}.mutableCopy;
        
        //old value 需要根据 keypath 遍历到最后一个元素才能决定取哪个 value
        //@"daughter.name"
        SEL getAttrSEL = sel_registerName(getterSELName.UTF8String);
        id oldValue = ((id(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL);
        NSRange range = [observerModel.keypath rangeOfString:getterSELName];
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
            [newValue setPyl_kvo_retainBy:self];
            [newValue pyl_kvo_isaSwizzleWithKeyPath:moreAttrs];
        }
        
        if (observerModel.options & PYLKVOOptionsOld) {
            dict[PYLKVOKeyOld] = oldValue;
        }
        if (observerModel.options & PYLKVOOptionsNew) {
            dict[PYLKVOKeyNew] = endNewValue;
        }
        ((void(*)(id,SEL,id,id,id))(void *)objc_msgSend)(observerModel.observer, @selector(pyl_kvo_observeValueForKeyPath:ofObject:change:), observerModel.keypath, rootListener, dict);
    }
    
    //调用父类实现设置新值
    IMP superIMP = class_getMethodImplementation(class_getSuperclass(object_getClass(self)), cmd);
    ((void(*)(id,SEL,id))(void *)superIMP)(self, cmd, newValue);
    
}

IMP pyl_kvo_impWithTypeEncoding(const char * typeEncoding) {
    NSString *type = [[NSString stringWithUTF8String:typeEncoding] substringFromIndex:@"v24@0:8".length];
    if ([type containsString:[NSString stringWithUTF8String:@encode(char)]]) {
        return (IMP)pyl_kvo_setter_char;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(short)]]) {
        return (IMP)pyl_kvo_setter_short;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(int)]]) {
        return (IMP)pyl_kvo_setter_int;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long)]]) {
        return (IMP)pyl_kvo_setter_long;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long long)]]) {
        return (IMP)pyl_kvo_setter_long_long;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned char)]]) {
        return (IMP)pyl_kvo_setter_unsigned_char;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
        return (IMP)pyl_kvo_setter_unsigned_short;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
        return (IMP)pyl_kvo_setter_unsigned_int;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long long)]]) {
        return (IMP)pyl_kvo_setter_unsigned_long_long;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
        return (IMP)pyl_kvo_setter_unsigned_long;
    
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(bool)]]) {
        return (IMP)pyl_kvo_setter_bool;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(float)]]) {
        return (IMP)pyl_kvo_setter_float;
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(double)]]) {
        return (IMP)pyl_kvo_setter_double;
    } else {
        return (IMP)pyl_kvo_setter_objc;
    }
}

NSString * pyl_kvo_getterSELName(SEL setterSEL) {
    NSString *methodName = [NSString stringWithFormat:@"%s", sel_getName(setterSEL)];
    methodName = [methodName substringFromIndex:3];
    methodName = [methodName substringToIndex:methodName.length-1]; //Daughter
    methodName = [methodName lowercaseString]; //daughter
    return methodName;
}

const char * pyl_kvo_subclassName(Class superclass) {
    NSString *name = [NSString stringWithFormat:@"%@%s", PYLKVOClassPrefix, class_getName(superclass)];
    return name.UTF8String;
}

- (void)pyl_kvo_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    self.pyl_kvo_observerModels = [[self.pyl_kvo_observerModels filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PYLKVOObserverModel *obj, NSDictionary<NSString *,id> * _Nullable bindings) {
        return obj.observer != observer || ![obj.keypath isEqualToString:keyPath];
    }]] mutableCopy];
    if (!self.pyl_kvo_observerModels.count) {
        //还原 isa
        object_setClass(self, class_getSuperclass(object_getClass(self)));
    }
}

- (void)pyl_kvo_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString*,id> *)change {
    //子类实现, 接收消息
}

@end
