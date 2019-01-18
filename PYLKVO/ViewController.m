//
//  ViewController.m
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "ViewController.h"
#import "Father.h"
#import "Daughter.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+PYLKVO.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    Father *f = [Father new];
    f.name = @"john";
    f.daughter = [Daughter new];
    f.daughter.name = @"jack";
    
    [f pyl_kvo_addObserver:self forKeyPath:@"daughter.age" options:PYLKVOOptionsNew];
//    [f addObserver:self forKeyPath:@"daughter.age" options:NSKeyValueObservingOptionNew context:NULL];
//    printClsMethods(object_getClass(f.daughter));
    
//    f.daughter = [Daughter new];
    [f.daughter setAge:4];
    
//    //打印 father 的 isa 和 方法列表
//    int a = 3;
//    ((void(*)(id,SEL,float))(void*)objc_msgSend)(self,sel_registerName("setBBB:"),a);
    char a = 'g';
    NSLog(@"%f", a);
}

-(void)setBBB:(double)newBBB {
    
}

- (void)pyl_kvo_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change {
    NSLog(@"%@, %@, %@", keyPath, object, change);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"%@, %@, %@", keyPath, object, change);
}

void printClsMethods(Class cls) {
    unsigned int outCount = 0;
    Method *methodList = class_copyMethodList(cls, &outCount);
    for (int i = 0; i < outCount; i++) {
        Method aMethod = *(methodList + i);
        SEL nameSEL = method_getName(aMethod);
        const char *name = sel_getName(nameSEL);
        printf("%s\n", name);
    }
}




@end
