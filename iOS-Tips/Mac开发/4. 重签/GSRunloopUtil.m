//
//  GSRunloopUtil.m
//  GSnitch
//
//  Created by lcd on 2018/6/7.
//  Copyright © 2018年 lcd. All rights reserved.
//

#import "GSRunloopUtil.h"

@implementation GSRunloopUtil

- (instancetype)init {
    if (self = [super init]) {
        self.isSuspend = NO;
    }
    return self;
}

-(void)run:(void (^)(void))block {
    self.isSuspend = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_TIME_NOW, 0), ^{
        while (!self.isSuspend) {
            block();
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    });
}

- (void)stop:(void (^)(void))complete {
    self.isSuspend = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        complete();
    });
}

@end
