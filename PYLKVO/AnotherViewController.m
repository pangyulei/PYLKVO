//
//  AnotherViewController.m
//  PYLKVO
//
//  Created by yulei pang on 2019/1/18.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "AnotherViewController.h"
#import "Father.h"
#import "Daughter.h"
#import "NSObject+PYLKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "PYLKVOObserverModel.h"
#import "NSObject+PYLKVOAttrs.h"

@interface AnotherViewController ()
@property (nonatomic, strong) Father *f;
@property (nonatomic, weak) AnotherViewController *ws;
@end

@implementation AnotherViewController
- (void)pyl_kvo_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change {
    NSLog(@"%@, %@, %@", keyPath, object, change);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@, %@, %@", keyPath, object, change);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self test_sys_kvo];
}

- (void)test_sys_kvo {
    _f = [Father new];
    Father *f = _f;
    f.name = @"john";
    f.daughterA = [Daughter new];
    f.daughterA.name = @"jack";
    
    [f addObserver:self forKeyPath:@"daughterA.name" options:NSKeyValueObservingOptionNew context:nil];

    f.daughterA.name = @"sim";
    f.daughterA.name = @"kitty";
}

- (void)test_pyl_kvo {
    _ws = self;
    
    // Do any additional setup after loading the view.
    _f = [Father new];
    Father *f = _f;
    f.name = @"john";
    f.daughterA = [Daughter new];
    f.daughterA.name = @"jack";
    
    [f pyl_kvo_addObserver:self forKeyPath:@"daughterA.success" options:PYLKVOOptionsNew|PYLKVOOptionsInitial];
    [f pyl_kvo_addObserver:self forKeyPath:@"daughterA.name" options:PYLKVOOptionsNew|PYLKVOOptionsInitial];
    
    f.daughterA.success = false;
    f.daughterA.name = @"sim";
    f.daughterA.name = @"kitty";
}

- (void)dealloc {
//    [_f pyl_kvo_removeObserver:self forKeyPath:@"daughter.success"];
    [_f pyl_kvo_removeObserver:self];
    printf("还原 %s\n", object_getClassName(object_getClass(_f)));
    printf("还原 %s\n", object_getClassName(object_getClass(_f.daughterA)));
}

@end
