//
//  NSObject+PYLKVO.h
//  PYLKVO
//
//  Created by yulei pang on 2019/1/17.
//  Copyright © 2019 pangyulei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, PYLKVOOptions) {
    PYLKVOOptionsNew = 1<<0, //1
    PYLKVOOptionsOld = 1<<1, //2
    PYLKVOOptionsInitial = 1<<2 //4
};

extern NSString * const PYLKVOKeyNew;
extern NSString * const PYLKVOKeyOld;

@interface NSObject (PYLKVO)

- (void)pyl_kvo_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(PYLKVOOptions)options;
- (void)pyl_kvo_removeObserver:(NSObject *)observer;
- (void)pyl_kvo_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
- (void)pyl_kvo_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString*,id> *)change;

@end
