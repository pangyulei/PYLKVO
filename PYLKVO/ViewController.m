//
//  ViewController.m
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import "ViewController.h"
#import "AnotherViewController.h"

@interface ViewController ()
@property (nonatomic, weak) UIViewController *vc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AnotherViewController *vc = [AnotherViewController new];
    vc.vc = self;
    _vc = vc;
    [self.navigationController pushViewController:vc animated:false];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"d" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"%@", _vc);
    }];
}

@end
