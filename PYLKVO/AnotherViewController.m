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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _ws = self;
    
    // Do any additional setup after loading the view.
    _f = [Father new];
    Father *f = _f;
    f.name = @"john";
    f.daughter = [Daughter new];
    f.daughter.name = @"jack";
    
    [f pyl_kvo_addObserver:self forKeyPath:@"daughter.success" options:PYLKVOOptionsNew|PYLKVOOptionsInitial];
    f.daughter.success = false;
}

- (void)dealloc {
//    [_f pyl_kvo_removeObserver:self forKeyPath:@"daughter.success"];
    [_f pyl_kvo_removeObserver:self];
    printf("还原 %s\n", object_getClassName(object_getClass(_f)));
}

@end
